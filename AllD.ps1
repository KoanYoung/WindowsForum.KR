<#
if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] 'Administrator')) {
        Write-Host "    [i] Elevate to Administrator"
        $CommandLine = "-ExecutionPolicy Bypass `"" + $MyInvocation.MyCommand.Path + "`" " + $MyInvocation.UnboundArguments
        Start-Process -FilePath PowerShell.exe -Verb Runas -ArgumentList $CommandLine
    }
#>

<#
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))  
{  
  $arguments = "& '" +$myinvocation.mycommand.definition + "'"
  Start-Process powershell -Verb runAs -ArgumentList $arguments
  # Break
}
#>

IF (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) 
{ Start-Process powershell.exe -Verb RunAs -ArgumentList "-noExit -noLogo -windowStyle Maximized -executionPolicy Bypass -File `"$PSCommandPath`""
; Exit $LastExitCode }

<#
If (!([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator')) {
    Write-Host "`t관리자권한으로 실행하지 않았습니다." -Back DarkRed -Fore Black
    Write-Host "`t[관리자]로 자동 다시 시작합니다." -Back DarkRed -Fore Black 

    Start-Sleep 1
    $psexe = (Get-Command 'powershell.exe').Source
    Start-Process $psexe -ArgumentList ("-ExecutionPolicy Bypass -File `"{0}`"" -F $PSCommandPath) -Verb RunAs 
	# 2>&1>$null
	# Try{ Set-ExecutionPolicy Bypass -force } Catch {}
	}
    # Exit
#>

<#
function Disable-ExecutionPolicy 
{($ctx = $executioncontext.gettype().getfield("_context","nonpublic,instance").getvalue( $executioncontext)).gettype().getfield("_authorizationManager","nonpublic,instance").setvalue($ctx, (new-object System.Management.Automation.AuthorizationManager "Microsoft.PowerShell"))} 

Disable-ExecutionPolicy  ps1\AllD.ps1
Disable-ExecutionPolicy Ps1\AllDHashl.ps1
#>

<#
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs; exit }
#>
<#
if([bool]([Security.Principal.WindowsIdentity]::GetCurrent()).Groups -notcontains "S-1-5-32-544" ){ Start Powershell -ArgumentList "& '$MyInvocation.MyCommand.Path'" -Verb runas }
#>

. "$PSScriptRoot\AllDHash.ps1"

$SSD = Get-PhysicalDisk | Where-Object { $_.MediaType -like "SSD" -and
$_.PhysicalLocation -notlike "*.vhd*" } 
$SSDRel = $SSD | Get-StorageReliabilityCounter

([PSCustomObject] @{
	'Devide ID' = $SSD.DeviceId 
	'Media Type' = $SSD.MediaType 
	'Bus Type' = $SSD.BusType 
	'SSD Wear' = $SSDRel.Wear
	'Temperature' = $SSDRel.Temperature
	'Health Status' = $SSD.HealthStatus
	'Operational Status' = $SSD.OperationalStatus
	'Read Errors Total' = $_.ReadErrorsTotal
	'Write Errors Total' = $_.WriteErrorsTotal 
} | Out-String).Trim()

Get-WmiObject Win32_LogicalDisk | 
ForMat-Table Caption, VolumeName, FileSystem,
@{N="Free(%)";E={"{0:N2} %" -f ((100 / ($_.Size / $_.FreeSpace)))}; 
Align='Right'},
@{N="Size(GB)";E={"{0:N2} GB" -f ($_.Size / 1Gb)}; Align='Right'}, 
@{N="Free(GB)";E={"{0:N2} GB" -f ($_.FreeSpace / 1Gb)}; Align='Right'},
@{N="Type";E={$driveType.Item([Int]$_.DriveType)}}, 
$ConfigManagerErrorCode, VolumeDirty

<#
$disksObject = @()
Get-WmiObject Win32_Volume | ForEach-Object {
    $VolObj = $_
    $ParObj = Get-Partition | Where-Object { $_.AccessPaths -contains $VolObj.DeviceID }
    If ($ParObj) {
        $disksObject += [PSCustomObject][Ordered]@{
        DiskID = $([String]$($ParObj.DiskNumber) + "-" + [String]$($ParObj.PartitionNumber)) -AS [String]
        # Mountpoint = $VolObj.Name
        Letter = $VolObj.DriveLetter
        Label = $VolObj.Label
        FileSystem = $VolObj.FileSystem
        'Capacity(GB)' = ([Math]::Round(($VolObj.Capacity / 1GB),2))
        'FreeSpace(GB)' = ([Math]::Round(($VolObj.FreeSpace / 1GB),2))
        'Free(%)' = ([Math]::Round(((($VolObj.FreeSpace / 1GB)/($VolObj.Capacity / 1GB)) * 100),0))
        }
    }
}
$disksObject | Sort-Object DiskID | Format-Table -Auto
#>

#
(get-disk | select Number, FriendlyName | Out-String).Trim()
Get-Volume | ForEach-Object {
    $VolObj = $_
    $ParObj = Get-Partition | Where-Object { $_.AccessPaths -contains 
	$VolObj.Path }
    IF( $ParObj ) {
        '{0,2} DN {1,1} PN {2,1} {3,6} {4,10} GB {5,10} GB {6}' -f 
		  $VolObj.DriveLetter,
          $ParObj.DiskNumber,
		  $ParObj.PartitionNumber,
          $VolObj.FileSystem, 
          ([Math]::Round($VolObj.Size/1GB,2)),
          ([Math]::Round($VolObj.SizeRemaining/1GB,2)),
          $VolObj.FileSystemLabel
    }
}

# $host.EnterNestedPrompt()