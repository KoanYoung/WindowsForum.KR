Param ($Folder, $USB, $Label, [Switch]$Format)
	
 If($Format){
   Format-Volume -driveLetter $USB -fileSystem FAT32 `
   -newFilesystemLabel $Label -Force | Out-Null }
 If(Test-Path $Folder) {
   Write-Warning "$Folder 가 이미 있어서 삭제합니다."
   Get-Item $Folder | Remove-Item -Rec -Force }
   
Start-Sleep 2			
$InsDir = 
"$Env:ProgramFiles (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment"
$PArch  = $env:Processor_Architecture
$BootFiles = "$InsDir\$PArch\Media"
$WimFile = "$InsDir\$PArch\en-us"

Write-Host "`n$Folder 와 작업할 임시 하위폴더를 만듭니다.`n" -Fore Green
New-Item -Path "$Folder\mount" -ItemType Directory | Out-Null
New-Item -Path "$Folder\media\sources" -Type directory | Out-Null

Write-Host "$BootFiles 에서 $Folder\media 로 복사합니다`n" -Fore Green
Get-ChildItem $BootFiles | ?{$_.Name -match 'bootmgr|boot|EFI|en-us|ko-kr'} |`
Copy-Item -Dest "$Folder\media" -Rec -Force -EA 0

Start-Sleep 1
Write-Host "$Folder\media 폴더내 영어,한국어 외 폴더는 삭제합니다. " -Fore Green
([System.IO.Directory]::GetDirectories("$Folder\media\Boot")) | `
?{$_ -NotMatch 'en-us|Fonts|ko-kr|Resources'} | Remove-Item -Rec -Force -EA 0
([System.IO.Directory]::GetDirectories("$Folder\media\EFI\Boot")) | `
?{$_ -NotMatch 'en-us|ko-kr'} | Remove-Item -Rec -Force -EA 0
([System.IO.Directory]::GetDirectories("$Folder\media\EFI\Microsoft\Boot")) | `
?{$_ -NotMatch 'en-us|Fonts|ko-kr|Resources'} | Remove-Item -Rec -Force -EA 0
Start-Sleep 1

Copy-Item "$WimFile\winpe.wim" -Dest "$Folder\media\sources"
Rename-Item -Path "$Folder\media\sources\winpe.wim" -NewName "boot.wim"
Dism /Mount-Image /ImageFile:"$Folder\media\sources\boot.wim" `
/Index:1 /MountDir:"$Folder\mount"
Start-Sleep 1

$Packs = [System.Collections.Generic.List[Object]]::New()
@(
'WinPE-WMI.cab', 'WinPE-NetFx.cab', 'WinPE-FMAPI.cab', 
'WinPE-Scripting.cab', 'WinPE-PowerShell.cab', 
'WinPE-SecureBootCmdlets.cab', 'WinPE-DismCmdlets.cab', 
'WinPE-StorageWMI.cab', 'WinPE-WDS-Tools.cab', 
'WinPE-SecureStartup.cab', 'WinPE-PmemCmdlets.cab',
'WinPE-EnhancedStorage.cab','WinPE-Dot3Svc.cab',
'WinPE-FontSupport-KO-KR.cab').ForEach({ $Packs.Add($_) })

$PacksLang = [System.Collections.Generic.List[Object]]::New()
@(
'WinPE-WMI_ko-kr.cab', 'WinPE-NetFx_ko-kr.cab', 
'WinPE-Scripting_ko-kr.cab', 'WinPE-PowerShell_ko-kr.cab',
'WinPE-DismCmdlets_ko-kr.cab','WinPE-StorageWMI_ko-kr.cab',
'WinPE-WDS-Tools_ko-kr.cab','WinPE-SecureStartup_ko-kr.cab',
'WinPE-EnhancedStorage_ko-kr.cab','WinPE-Dot3Svc_ko-kr.cab',
'WinPE-PmemCmdlets_ko-kr.cab','lp.cab' ).ForEach({ $PacksLang.Add($_) })

ForEach($Cab In $Packs) {
Dism /Image:"$Folder\mount" /LogLevel:2 /Add-Package `
/PackagePath:"$InsDir\$PArch\WinPE_OCs\$Cab" }

ForEach($Cab2 In $PacksLang) {
Dism /Image:"$Folder\mount" /LogLevel:2 /Add-Package `
/PackagePath:"$InsDir\$PArch\WinPE_OCs\ko-kr\$Cab2" }
 
Dism /Image:"$Folder\mount" /Set-AllIntl:ko-KR `
/Set-TimeZone:'Korea Standard Time'
Start-Sleep 1

Write-Host "`n현재 실컴에 있는 IME 관련 파일.폴더를 마운트된 곳에 복사합니다." `
-Fore Green

'Fonts','IME' | %{ Get-Item $Env:WinDir\$_ | `
Copy-Item -Dest "$Folder\mount\Windows" -Rec -Force -EA 0 };
([IO.Directory]::GetFileSystemEntries("$Folder\mount\Windows\IME")).Where({`
$_ -NotMatch 'IMEKR'}) | Remove-Item -Rec -Force -EA 0
Start-Sleep 1

@('CTFMON.EXE','msctfime.ime','MSUTB.DLL','IME').ForEach({`
Get-Item $Env:WinDir\System32\$_}) | `
Copy-Item -Dest "$Folder\mount\Windows\System32" -Rec -Force -EA 0
Start-Sleep 1

([IO.Directory]::GetFileSystemEntries(`
"$Folder\mount\Windows\System32\IME")).Where({$_ -NotMatch 'IMEKR|SHARED'}) |`
Remove-Item -Rec -Force -EA 0
Get-Item "$Folder\mount\Windows\System32\IME\IMEKR\IMKRAPI.DLL" | `
Remove-Item -Force
Copy-Item $PSScriptRoot\MsCtfMonitor.dll -Dest `
"$Folder\mount\Windows\System32" -Force
Copy-Item $PSScriptRoot\IMKRApi.dll -Dest `
"$Folder\mount\Windows\System32\IME\IMEKR" -Force
Start-Sleep 1

Write-Host "`n새로 만들어질 PE 에 한글입력이 되게 레지를 PE 에 적용합니다.`n" `
-Fore Green

REG Load HKLM\PEKor "$Folder\mount\Windows\System32\Config\Software"
REG Load HKU\KorUser "$Folder\mount\Users\Default\NtUser.dat"
Start-Sleep 2
REG ADD "HKLM\PEKor\Microsoft\PowerShell\1\ShellIds\microsoft.powershell" `
/v "Path" /d "%SystemRoot%\system32\windowspowershell\v1.0\powershell.exe" /f
REG ADD "HKLM\PEKor\Microsoft\PowerShell\1\ShellIds\microsoft.powershell" `
/v "ExecutionPolicy" /d "Bypass" /f

REG ADD "HKLM\PEKor\Microsoft\CTF" /v "StartOnNoTaskEng" /t REG_DWORD /d 1 /f 

REG ADD "HKLM\PEKor\Microsoft\IME\15.0\IMEKR" /v "Dictionary" `
/t REG_EXPAND_SZ /d "%SystemRoot%\IME\IMEKR\DICTS\IMKRHJD.LEX" /f

REG ADD "HKLM\PEKor\Microsoft\IME\15.0\IMEKR\directories" `
/v "DictionaryPath" /t REG_EXPAND_SZ /d "%SystemRoot%\IME\IMEKR\DICTS\" /f 

REG ADD "HKLM\PEKor\Microsoft\IME\15.0\IMEKR\directories" /v "ModulePath" `
/t REG_EXPAND_SZ /d "%SystemRoot%\System32\IME\IMEKR\" /f 

REG ADD "HKLM\PEKor\Microsoft\IME\15.0\IMEKR\version" /ve `
/d "15.0.0000.0" /f 

REG ADD `
"HKU\KorUser\Software\Microsoft\CTF\TIP\{A028AE76-01B1-46C2-99C4-ACD9858AE02F}\LanguageProfile\0x00000412\{B5FE1F02-D5F2-4445-9C03-C568F23C99A1}" /v "Enable" /t REG_DWORD /d 1 /f

REG ADD `
"HKU\KorUser\Software\Microsoft\CTF\SortOrder\AssemblyItem\0x00000412\{34745C63-B2F0-4784-8B67-5E12C8701A31}\00000000" /v "CLSID" `
/d "{A028AE76-01B1-46C2-99C4-ACD9858AE02F}" /f

REG ADD `
"HKU\KorUser\Software\Microsoft\CTF\SortOrder\AssemblyItem\0x00000412\{34745C63-B2F0-4784-8B67-5E12C8701A31}\00000000" /v "Profile" `
/d "{B5FE1F02-D5F2-4445-9C03-C568F23C99A1}" /f 

REG ADD `
"HKU\KorUser\Software\Microsoft\CTF\SortOrder\AssemblyItem\0x00000412\{34745C63-B2F0-4784-8B67-5E12C8701A31}\00000000" `
/v "KeyboardLayout" /t REG_DWORD /d 0 /f 

REG ADD "HKU\KorUser\Software\Microsoft\CTF\SortOrder\Language" /v "00000000" `
/d "00000412" /f 
REG ADD "HKU\KorUser\Software\Microsoft\CTF\HiddenDummyLayouts" /v "00000412" `
/d "00000412" /f 

REG ADD `
"HKU\KorUser\Software\Microsoft\CTF\Assemblies\0x00000412\{34745C63-B2F0-4784-8B67-5E12C8701A31}" `
/v "Default" /d "{A028AE76-01B1-46C2-99C4-ACD9858AE02F}" /f 

REG ADD `
"HKU\KorUser\Software\Microsoft\CTF\Assemblies\0x00000412\{34745C63-B2F0-4784-8B67-5E12C8701A31}" `
/v "Profile" /d "{B5FE1F02-D5F2-4445-9C03-C568F23C99A1}" /f 

REG ADD `
"HKU\KorUser\Software\Microsoft\CTF\Assemblies\0x00000412\{34745C63-B2F0-4784-8B67-5E12C8701A31}" `
/v "KeyboardLayout" /t REG_DWORD /d "04120412" /f 

REG ADD "HKU\KorUser\Control Panel\Mouse" /v MouseSensitivity /t REG_SZ /d 20 /f
REG ADD "HKU\KorUser\Control Panel\Mouse" /v MouseSpeed /t REG_SZ /d 2 /f

Start-Sleep 2
REG Unload HKLM\PEKor
REG Unload HKU\KorUser
Start-Sleep 2

[GC]::Collect()
Start-Sleep 2

Write-Host `
"`nPE 시작때 한글입력을 위한 .dll 등록실행을 startnet.cmd 에 추가했습니다" `
-Fore Green
@"
@echo off 
RegSvr32 /S %WinDir%\System32\MSUTB.DLL 
RegSvr32 /S %WinDir%\System32\MsCtfMonitor.DLL 
RegSvr32 /S %WinDir%\System32\IME\shared\IMETIP.DLL 
RegSvr32 /S %WinDir%\System32\IME\shared\IMEAPIS.DLL 
RegSvr32 /S %WinDir%\System32\IME\shared\IMJKAPI.DLL 
RegSvr32 /S %WinDir%\System32\IME\shared\MSCAND20.DLL 
RegSvr32 /S %WinDir%\System32\IME\IMEKR\IMKRTIP.DLL 
RegSvr32 /S %WinDir%\System32\IME\IMEKR\IMKRAPI.DLL 
RegSvr32 /S %WinDir%\System32\IME\IMEKR\DICTS\IMKRHJD.DLL
Start CTFMON.EXE
wpeinit
"@ | Set-Content "$Folder\mount\Windows\System32\startnet.cmd" -Force

Start-Sleep 1
Dism /Unmount-Image /MountDir:"$Folder\mount" /Commit
Start-Sleep 2
bootsect /nt60 "$($USB):" /force /mbr
Start-Sleep 1

Write-Host "`n$Folder\media 에서 $($USB):\ 로 복사합니다`n" -Fore Green
xcopy /herkyq $Folder\media\*.* "$($USB):"
Write-Host "`n마지막으로, 작업을 위해 만들었던 $Folder 폴더를 삭제합니다.`n" `
-Fore Magenta
Remove-Item $Folder -Rec -Force


