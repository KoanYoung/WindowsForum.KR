Param ($Folder, $USB, $Label, [Switch]$Format)
	
 If($Format){
   Format-Volume -driveLetter $USB -fileSystem FAT32 `
   -newFilesystemLabel $Label -Force | Out-Null }
 If(Test-Path $Folder) {
   Write-Warning "$Folder 가 이미 있어서 삭제합니다."
   Get-Item $Folder | Remove-Item -Rec -Force }
   
Start-Sleep 2			
$InsDir = 
"$env:ProgramFiles (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment"
$PArch  = $env:Processor_Architecture
$BootFiles = "$InsDir\$PArch\Media"
$WimFile = "$InsDir\$PArch\en-us"

Write-Host "`n$Folder 와 작업할 임시 하위폴더를 만듭니다.`n" -Fore Green
New-Item -Path "$Folder\mount" -ItemType Directory | Out-Null
New-Item -Path "$Folder\media\sources" -Type directory | Out-Null

Write-Host "$BootFiles 에서 $Folder\media 로 복사합니다`n" -Fore Green
xcopy /herkyq $Bootfiles "$Folder\media"
Copy-Item "$WimFile\winpe.wim" -Dest "$Folder\media\sources"
Rename-Item -Path "$Folder\media\sources\winpe.wim" -NewName "boot.wim"
Dism /Mount-Image /ImageFile:"$Folder\media\sources\boot.wim" `
/Index:1 /MountDir:"$Folder\mount"
Start-Sleep 1

$Packs = [System.Collections.Generic.List[Object]]::New()
@(
'WinPE-WMI.cab', 'WinPE-NetFx.cab', 
'WinPE-FMAPI.cab', 'WinPE-Scripting.cab', 
'WinPE-PowerShell.cab', 'WinPE-SecureBootCmdlets.cab', 
'WinPE-DismCmdlets.cab', 'WinPE-StorageWMI.cab', 
'WinPE-WDS-Tools.cab', 'WinPE-SecureStartup.cab', 'WinPE-EnhancedStorage.cab', 'WinPE-WinReCfg.cab', 
'WinPE-Dot3Svc.cab', 'WinPE-PPPoE.cab',
'WinPE-FontSupport-KO-KR.cab').ForEach({ $Packs.Add($_) })

$PacksLang = [System.Collections.Generic.List[Object]]::New()
@(
'WinPE-WMI_ko-kr.cab', 'WinPE-NetFx_ko-kr.cab', 
'WinPE-Scripting_ko-kr.cab', 'WinPE-PowerShell_ko-kr.cab',
'WinPE-DismCmdlets_ko-kr.cab','WinPE-StorageWMI_ko-kr.cab', 'WinPE-WDS-Tools_ko-kr.cab','WinPE-SecureStartup_ko-kr.cab', 'WinPE-EnhancedStorage_ko-kr.cab', 'WinPE-WinReCfg_ko-kr.cab', 'WinPE-Dot3Svc_ko-kr.cab', 'WinPE-PPPoE_ko-kr.cab', 'lp.cab' `
 ).ForEach({ $PacksLang.Add($_) })

ForEach($Cab In $Packs) {
Dism /Image:"$Folder\mount" /LogLevel:2 /Add-Package `
/PackagePath:"$InsDir\amd64\WinPE_OCs\$Cab" }

ForEach($Cab2 In $PacksLang) {
Dism /Image:"$Folder\mount" /LogLevel:2 /Add-Package `
/PackagePath:"$InsDir\amd64\WinPE_OCs\ko-kr\$Cab2" }
 
Dism /Image:"$Folder\mount" /Set-AllIntl:ko-KR `
/Set-TimeZone:'Korea Standard Time'
Start-Sleep 1

Write-Host "`nPE 시작때 실행될 레지적용을 기존 startnet.cmd 에 추가했습니다" -Fore Green
@"
reg add HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\microsoft.powershell /v "Path" /d %SystemRoot%\system32\windowspowershell\v1.0\powershell.exe /f
reg add HKLM\SOFTWARE\Microsoft\PowerShell\1\ShellIds\microsoft.powershell /v "ExecutionPolicy" /d "unrestricted" /f                   
reg add "HKCU\Control Panel\Mouse" /v MouseSensitivity /t REG_SZ /d 20 /f
reg add "HKCU\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 2 /f
cls
wpeinit
"@ | Set-Content "$Folder\mount\Windows\System32\startnet.cmd" `
-Force -Encoding UTF8

Start-Sleep 1
Dism /Unmount-Image /MountDir:"$Folder\mount" /Commit
Start-Sleep 2
bootsect /nt60 "$($USB):" /force /mbr
Start-Sleep 1

Write-Host "`n$Folder\media 에서 $($USB):\ 로 복사합니다`n" -Fore Green
xcopy /herkyq $Folder\media\*.* "$($USB):"
Write-Host "`n마지막으로 작업을 위해 만들었던 $Folder 폴더를 삭제합니다.`n" -Fore Magenta
Remove-Item $Folder -Rec -Force


