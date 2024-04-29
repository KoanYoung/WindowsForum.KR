function make-usbpe {
    Param (
	[Parameter(Position=0)][Alias('to')][string]$Destination,
    [Parameter(Position=1)][Alias('ul')][string]$USBLetter,
    [Switch]$Format
	)
	
    if($Format){
        format-volume -driveLetter $USBLetter -fileSystem FAT32 -newFilesystemLabel 'YSS-PE' -force
    }
    if(Test-Path "$Destination") {
        if((Get-Item "$Destination").GetDirectories().Length -gt 0) {
            Write-Warning "$Destination already exists."
            break
    }}
            else { New-Item -Path "$Destination" -Type directory -verbose }
			
$InstallDirectory = "$env:programfiles (x86)\Windows Kits\10\Assessment and Deployment Kit\Windows Preinstallation Environment"
# $InstallDirectory = "F:\Windows Kits\10\Assessment and Deployment Kit"
$PArchitecture  = $env:Processor_Architecture
$bootFiles = "$InstallDirectory\$PArchitecture\Media"
$winPeFile = "$InstallDirectory\$PArchitecture\en-us"

New-Item -Path "$Destination\media" -Type directory -verbose
New-Item -Path "$Destination\mount" -Type directory -verbose
New-Item -Path "$Destination\media\sources" -type directory -verbose
start-sleep 3
xcopy /herky $bootfiles $Destination\media
copy-item $winPeFile\winpe.wim $Destination\media\sources -verbose
Rename-Item -Path "$Destination\media\sources\winpe.wim" -NewName "boot.wim" -verbose
start-sleep 3

Dism /mount-wim /wimfile:"$Destination\media\sources\boot.wim" /Index:1 /mountdir:"$Destination\mount"
start-sleep 3
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-WMI.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\en-us\WinPE-WMI_en-us.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-NetFx.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\en-us\WinPE-NetFx_en-us.cab"
Dism /Image:"$Destination\mount" /add-package /packagepath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-FMAPI.cab"
Dism /Image:"$Destination\mount" /add-package /packagepath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-Scripting.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\en-us\WinPE-Scripting_en-us.cab"
Dism /Image:"$Destination\mount" /add-package /packagepath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-PowerShell.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\en-us\WinPE-PowerShell_en-us.cab"
Dism /Image:"$Destination\mount" /add-package /packagepath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-SecureBootCmdlets.cab"
Dism /Image:"$Destination\mount" /add-package /packagepath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-HTA.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\en-us\WinPE-HTA_en-us.cab"
Dism /Image:"$Destination\mount" /add-package /packagepath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-DismCmdlets.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\en-us\WinPE-DismCmdlets_en-us.cab"
Dism /Image:"$Destination\mount" /add-package /packagepath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-StorageWMI.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\en-us\WinPE-StorageWMI_en-us.cab"
Dism /Image:"$Destination\mount" /add-package /packagepath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-PlatformId.cab" /ignorecheck
Dism /Image:"$Destination\mount" /add-package /packagepath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-WDS-Tools.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\en-us\WinPE-WDS-Tools_en-us.cab"
Dism /Image:"$Destination\mount" /add-package /packagepath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-SecureStartup.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\en-us\WinPE-SecureStartup_en-us.cab"
Dism /Image:"$Destination\mount" /add-package /packagepath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-EnhancedStorage.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\en-us\WinPE-EnhancedStorage_en-us.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-WinReCfg.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\en-us\WinPE-WinReCfg_en-us.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-Dot3Svc.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\en-us\WinPE-Dot3Svc_en-us.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-PPPoE.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\en-us\WinPE-PPPoE_en-us.cab"
# Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\WinPE-FontSupport-en-us.cab"
Dism /Image:"$Destination\mount" /Add-Package /PackagePath:"$InstallDirectory\amd64\WinPE_OCs\en-us\lp.cab"
start-sleep 3
dism /image:"$Destination\mount" /set-InputLocale:en-us
dism /image:"$Destination\mount" /set-AllIntl:en-us
start-sleep 3
dism /image:"$Destination\mount" /set-LayeredDriver:4

start-sleep 10
Dism /Unmount-Wim /MountDir:"$Destination\mount" /Commit
start-sleep 3
bootsect /nt60 "$($USBLetter):" /force /mbr
# start-sleep 3
# compact /u $Destination\media
start-sleep 3
xcopy /herky $Destination\media\*.* "$($USBLetter):"
}
