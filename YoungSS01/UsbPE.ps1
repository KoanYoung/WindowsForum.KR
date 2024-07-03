Param ($Fol, $USB, $Lbl, [Switch]$Format)
	
 If($Format){
   Format-Volume -driveLetter $USB -fileSystem NTFS `
   -newFilesystemLabel $Lbl -Force | Out-Null }
 If(Test-Path "$Fol") {
   Write-Warning "$Fol 폴더가 이미 존재합니다. 삭제합니다.."
   Remove-Item $Fol -Rec -Force
   Start-Sleep 1
   New-Item $Fol -ItemType Directory | Out-Null }
	   
Start-Sleep 1
# ${env:ProgramFiles(x86)}

$InsDir = 
"$env:ProgramFiles (x86)\Windows Kits\10\Assessment and Deployment Kit"+`
"\Windows Preinstallation Environment"
$PArch  = $env:Processor_Architecture
$BootFiles = "$InsDir\$PArch\Media"
$WimFile = "$InsDir\$PArch\en-us"

New-Item -Path "$Fol\media\sources" -Type directory | Out-Null
New-Item -Path "$Fol\mount" -Type directory | Out-Null

Write-Host "`n$BootFiles 에서 $Folder\media 로 일부 추려서 복사합니다`n" `
-Fore Green
Get-ChildItem $BootFiles | ?{$_.Name -match 'bootmgr|boot|EFI|en-us|ko-kr'} |`
Copy-Item -Dest "$Fol\media" -Rec -Force -EA 0

Start-Sleep 1
Write-Host "영어,한국어 외 폴더는 삭제합니다. " -Fore Green
([System.IO.Directory]::GetDirectories("$Fol\media\Boot")) | `
?{$_ -NotMatch 'en-us|Fonts|ko-kr|Resources'} | Remove-Item -Rec -Force -EA 0
([System.IO.Directory]::GetDirectories("$Fol\media\EFI\Boot")) | `
?{$_ -NotMatch 'en-us|ko-kr'} | Remove-Item -Rec -Force -EA 0
([System.IO.Directory]::GetDirectories("$Fol\media\EFI\Microsoft\Boot")) | `
?{$_ -NotMatch 'en-us|Fonts|ko-kr|Resources'} | Remove-Item -Rec -Force -EA 0
Start-Sleep 1

Copy-Item "$WimFile\winpe.wim" -Dest "$Fol\media\sources"
Rename-Item -Path "$Fol\media\sources\winpe.wim" -NewName "boot.wim"
Dism /Mount-Image /ImageFile:"$Fol\media\sources\boot.wim" `
/Index:1 /MountDir:"$Fol\mount"
Start-Sleep 1

$Packs = [System.Collections.Generic.List[Object]]::New()
@(
'WinPE-WMI.cab', 'WinPE-NetFx.cab', 'WinPE-FMAPI.cab',
'WinPE-Scripting.cab', 'WinPE-PowerShell.cab', 
'WinPE-SecureBootCmdlets.cab', 'WinPE-DismCmdlets.cab',
'WinPE-StorageWMI.cab', 'WinPE-PmemCmdlets.cab',
'WinPE-WDS-Tools.cab', 'WinPE-SecureStartup.cab', 
'WinPE-EnhancedStorage.cab','WinPE-Dot3Svc.cab').ForEach({ $Packs.Add($_) })

$PacksLang = [System.Collections.Generic.List[Object]]::New()
@(
'WinPE-WMI_en-us.cab', 'WinPE-NetFx_en-us.cab', 
'WinPE-Scripting_en-us.cab','WinPE-PowerShell_en-us.cab',
'WinPE-DismCmdlets_en-us.cab','WinPE-StorageWMI_en-us.cab', 
'WinPE-WDS-Tools_en-us.cab','WinPE-SecureStartup_en-us.cab', 
'WinPE-EnhancedStorage_en-us.cab','WinPE-PmemCmdlets_en-us.cab',
'WinPE-Dot3Svc_en-us.cab', 'lp.cab').ForEach({ $PacksLang.Add($_) })

ForEach($Cab In $Packs) {
Dism /Image:"$Fol\mount" /LogLevel:2 /Add-Package `
/PackagePath:"$InsDir\amd64\WinPE_OCs\$Cab" }

ForEach($Cab2 In $PacksLang) {
Dism /Image:"$Fol\mount" /LogLevel:2 /Add-Package `
/PackagePath:"$InsDir\amd64\WinPE_OCs\en-us\$Cab2" }
 
Dism /Image:"$Fol\mount" /Set-AllIntl:en-us `
/Set-TimeZone:'Korea Standard Time'
Dism /Image:"$Fol\mount" /Set-ScratchSpace:256

<# Get-Item .\PS1\PEEnv.ps1 | Copy-Item -dest "$Fol\mount\Windows\System32" `
-Force -Ver #>

Write-Host "`n 필요한 레지스트리를 미리 적용합니다.`n" -Fore Green

Reg Load HKLM\PEEn "$Fol\mount\Windows\System32\Config\Software"
Reg Load HKU\EngUser "$Fol\mount\Users\Default\NtUser.dat"
Start-Sleep 2

reg add "HKLM\PEEn\Microsoft\PowerShell\1\ShellIds\microsoft.powershell" /v "ExecutionPolicy" /d "Bypass" /f                   

reg add "HKU\EngUser\Control Panel\Mouse" /v MouseSensitivity /t REG_SZ /d 20 /f
reg add "HKU\EngUser\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 2 /f
reg add "HKU\EngUser\Control Panel\Desktop" /v WheelScrollLines `
/t REG_SZ /d 8 /f

Start-Sleep 1
Reg Unload HKLM\PEEn;
Reg Unload HKU\EngUser;
Start-Sleep 2
[GC]::Collect()
Start-Sleep 2

Dism /Unmount-Image /MountDir:"$Fol\mount" /Commit
Start-Sleep 2
bootsect /nt60 "$($USB):" /force /mbr
Start-Sleep 1

Write-Host "`n$Fol\media 에서 $($USB):\ 로 복사합니다`n" -Fore Green
xcopy /herkyq $Fol\media\*.* "$($USB):"
Write-Host "`n마지막으로 작업을 위해 만들었던 $Fol 폴더를 삭제합니다.`n" `
-Fore Magenta
Remove-Item $Fol -Rec -Force


