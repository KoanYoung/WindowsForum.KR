Param ($Mount, $USB, $Label, [Switch]$Format)
	
 If($Format){
   Format-Volume -driveLetter $USB -fileSystem FAT32 `
   -newFilesystemLabel $Label -Force | Out-Null }
 If(Test-Path "$Mount") {
   Write-Warning "$Mount already exists. Removing.."
   Remove-Item $Mount -Rec -Force
   Start-Sleep 1
   New-Item $Mount -ItemType Directory | Out-Null }
	   
Start-Sleep 1			
$InsDir = 
"$env:ProgramFiles (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment"
$PArch  = $env:Processor_Architecture
$BootFiles = "$InsDir\$PArch\Media"
$WimFile = "$InsDir\$PArch\en-us"

New-Item -Path "$Mount\media\sources" -Type directory | Out-Null
New-Item -Path "$Mount\mount" -Type directory | Out-Null

Write-Host "$BootFiles 에서 $Mount\media 로 복사합니다`n" -Fore Green
xcopy /herkyq $Bootfiles $Mount\media
Copy-Item "$WimFile\winpe.wim" -Dest "$Mount\media\sources"
Rename-Item -Path "$Mount\media\sources\winpe.wim" -NewName "boot.wim"
Dism /Mount-Image /ImageFile:"$Mount\media\sources\boot.wim" `
/Index:1 /MountDir:"$Mount\mount"
Start-Sleep 1

$Packs = [System.Collections.Generic.List[Object]]::New()
@(
'WinPE-WMI.cab', 'WinPE-NetFx.cab', 
'WinPE-FMAPI.cab', 'WinPE-Scripting.cab', 
'WinPE-PowerShell.cab', 'WinPE-SecureBootCmdlets.cab', 
'WinPE-DismCmdlets.cab', 'WinPE-StorageWMI.cab', 
'WinPE-WDS-Tools.cab', 'WinPE-SecureStartup.cab', 'WinPE-EnhancedStorage.cab', 'WinPE-WinReCfg.cab', 
'WinPE-Dot3Svc.cab', 'WinPE-PPPoE.cab').ForEach({ $Packs.Add($_) })

$PacksLang = [System.Collections.Generic.List[Object]]::New()
@(
'WinPE-WMI_en-us.cab', 'WinPE-NetFx_en-us.cab', 
'WinPE-Scripting_en-us.cab', 'WinPE-PowerShell_en-us.cab',
'WinPE-DismCmdlets_en-us.cab','WinPE-StorageWMI_en-us.cab', 'WinPE-WDS-Tools_en-us.cab','WinPE-SecureStartup_en-us.cab', 'WinPE-EnhancedStorage_en-us.cab', 'WinPE-WinReCfg_en-us.cab', 'WinPE-Dot3Svc_en-us.cab', 'WinPE-PPPoE_en-us.cab', 'lp.cab' `
 ).ForEach({ $PacksLang.Add($_) })

ForEach($Cab In $Packs) {
Dism /Image:"$Mount\mount" /LogLevel:2 /Add-Package `
/PackagePath:"$InsDir\amd64\WinPE_OCs\$Cab" }

ForEach($Cab2 In $PacksLang) {
Dism /Image:"$Mount\mount" /LogLevel:2 /Add-Package `
/PackagePath:"$InsDir\amd64\WinPE_OCs\en-us\$Cab2" }
 
Dism /Image:"$Mount\mount" /Set-AllIntl:en-us `
/Set-TimeZone:'Korea Standard Time' 
# /Set-LayeredDriver:2

Start-Sleep 1
Dism /Unmount-Image /MountDir:"$Mount\mount" /Commit
Start-Sleep 2
bootsect /nt60 "$($USB):" /force /mbr
Start-Sleep 1

Write-Host "`n$Mount\media 에서 $($USB):\ 로 복사합니다`n" -Fore Green
xcopy /herkyq $Mount\media\*.* "$($USB):"
Write-Host "`n마지막으로 작업을 위해 만들었던 $Mount 폴더를 삭제합니다.`n" -Fore Magenta
Remove-Item $Mount -Rec -Force


