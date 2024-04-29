Function Get-IsoLocation
{
    [CmdletBinding()]
    [OutputType([string])]
    Param
    (
        [Parameter(
            Mandatory = $false,
            Position = 0)]
        [String]$WindowTitle = "Opening For .ISO",

        [Parameter(
            Mandatory = $true,
            ValueFromPipelineByPropertyName = $true,
            HelpMessage = "Initial Directory for browsing",
            Position = 1)]
        [String]$RootDir
    )
    Add-Type -AssemblyName System.Windows.Forms
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Title = $WindowTitle
    
    if (-Not [String]::IsNullOrWhiteSpace($RootDir))
    {
        $OpenFileDialog.InitialDirectory = $RootDir
    }
    $OpenFileDialog.ShowHelp = $true
    $OpenFileDialog.ShowDialog() | Out-Null
    return $OpenFileDialog.Filename
}

Write-Host "`n"
Write-Host "  Start Path To Choose .ISO " -ForeGroundColor Red
Write-Host "`n"
Write-Host "  ==> " -noNewline
$InputDir = Read-Host
# $InputDir = (Read-Host -prompt "`n`nISO Path?`n`n")
$IsoPath = Get-IsoLocation -RootDir $InputDir
# $IsoPath = 
$Volumes = (Get-Volume).Where({$_.DriveLetter}).DriveLetter
Mount-DiskImage -ImagePath $IsoPath
$ISO = (Compare-Object -ReferenceObject $Volumes -DifferenceObject (Get-Volume).Where({$_.DriveLetter}).DriveLetter).InputObject
Start-Sleep 2

Write-Host " `nPath You Want in C Drive" -ForeGroundColor Red
Write-Host "  ==> " -noNewline
$InputTempFolder = Read-Host
New-Item $InputTempFolder -Itemtype directory
Start-Sleep 2
robocopy "$($ISO):\" $InputTempFolder /e /copyall
# Set-Location -Path "$($ISO):\boot"
Write-Host "`n"
Write-Host "  Input USB Drive Letter`n" -ForeGroundColor Red
Write-Host "`n"
Write-Host "  ==> " -noNewline
$USBLetter = Read-Host

bootsect.exe /nt60 "$($USBLetter):"

If(Test-Path "$($ISO):\sources\install.wim")
{
Dism /Split-Image /ImageFile:"$InputTempFolder\sources\install.wim" /SWMFile:"$InputTempFolder\sources\install.swm" /FileSize:3500
gci -path "$InputTempFolder\sources\install.wim" | set-itemproperty -name IsReadOnly -value $false
Remove-Item $InputTempFolder\sources\install.wim -ver
}

Else
{ gci -path "$InputTempFolder\sources\install.esd" | set-itemproperty -name IsReadOnly -value $false
}

Start-Sleep 2
robocopy $InputTempFolder "$($USBLetter):\" /e /copyall
Start-Sleep 2
Dismount-Diskimage -imagepath $IsoPath
# Set-Location $env:UserProfile\Downloads
Remove-Item $InputTempFolder -rec -force -ver