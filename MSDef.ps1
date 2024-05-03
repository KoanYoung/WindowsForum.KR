Param([String]$OffOnList, [Int]$Sel)

$RegPE = "HKLM:\Off_Defender\ControlSet001\Services"
$Reg = "HKLM:\System\CurrentControlSet\Services"
$DefSvc = [Ordered] @{
'MpsDrv'=3; 'MdCoreSvc'=2; 'MpsSvc'=2; 'SecurityHealthService'=3; 
'Sense'=3; 'WpcMonSvc'=3; 'WdBoot'=0; 'WdFilter'=0; 'WdNisDrv'=3; 
'WdNisSvc'=3; 'WscSvc'=2; 'WinDefend'=2; 'SgrmAgent'=0; 'SgrmBroker'=2;
'MsSecCore'=0; 'MsSecFlt'=3}

Function Indexing {
   $Input | %{ $Index=0 }{$_ | Add-Member INDEX ($Index++) -PassThru} }

Switch($OffOnList) {
 'Off' 
 { $sParams = @{
   FilePath     = 'reg.exe'
   ArgumentList = 
   "Load `"HKLM\Off_Defender`" C:\Windows\System32\Config\System"
   WindowStyle  = 'Hidden'
   Wait         = $True
   PassThru     = $True }
   $Proc = Start-Process @sParams
    
   If(-Not $Proc.ExitCode) {
   Write-Host "`nSuccessfully [Loaded] HKLM\Off_Defender!" -Fore Blue }
   Else { Throw $Proc.ExitCode }
   
 ForEach($Svc In $DefSvc.GetEnumerator()) 
 { If(Test-Path "$RegPE\$($Svc.Key)") 
  { 
   Set-ItemProperty -Path "$RegPE\$($Svc.Key)" -Type DWord `
   -Name 'Start' -Value 4 -Force -ErrorAction SilentlyContinue
   Start-Sleep 1
   Get-ItemProperty "$RegPE\$($Svc.Key)" -EA 0 | `
   Select-Object PSChildName,Start,ImagePath 
  }
 } 
   
   [GC]::Collect()
   [GC]::WaitForPendingFinalizers()
   Start-Sleep 2; Write-Host "`r"
   Reg.exe Unload "HKLM\Off_Defender"
   Write-Host "[UnLoaded] HKLM\Off_Defender!" -Fore Green
}

 'On' 
  { ForEach($Svc In $DefSvc.GetEnumerator())
    {   
    Set-ItemProperty -Path "$Reg\$($Svc.Key)" -Type DWord `
	-Name 'Start' -Value "$Reg\$($Svc.Value)" -Force -EA 0
    Start-Sleep 1
	Get-ItemProperty "$Reg\$($Svc.Key)" -EA 0 | `
	Select-Object PSChildName,Start,ImagePath 
	Start-Sleep 1
	# Get-ScheduledTask *defender* | Enable-ScheduledTask
   }
}
    
 'List'
 { ($DefSvc.GetEnumerator()).ForEach({
	Get-Service -Name $_.Key }) | Format-Table -Auto | `
	Out-String | %{$_.Trim()}; "`r"
    $DefSvc.GetEnumerator() | %{ 
    Get-ItemProperty "$Reg\$($_.Key)" -EA 0 } | Indexing | `
	Select-Object INDEX,PSChildName,Start,ImagePath | `
    Out-String | %{$_.Trim()}; }
	
  Default {}
}  
   If($Sel -ne $Null) {
    $Enum = ($DefSvc.GetEnumerator() | Indexing)
    Set-ItemProperty -Path "$Reg\$($Enum.Name[$Sel])" `
   -Type DWord -Name 'Start' -Value "$($Enum.Value[$Sel])" -EA 0 }