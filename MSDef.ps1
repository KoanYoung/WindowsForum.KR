 Param([String]$OffOnList, [String]$Sel)

  $RegPE = "HKLM:\Off_Defender\ControlSet001\Services"
  $Reg = "HKLM:\System\CurrentControlSet\Services"
  $DefSvc = [Ordered] @{
  'SecurityHealthService'=3; 'Sense'=3; 'WpcMonSvc'=3; 'WdBoot'=0;
  'WdFilter'=0; 'WdNisDrv'=3; 'WdNisSvc'=3; 'WscSvc'=2;
  'WinDefend'=2; 'MdCoreSvc'=2; 'SgrmAgent'=0; 'SgrmBroker'=2; 
  'MsSecCore'=0; 'MsSecFlt'=3; 'MpsDrv'=3;'MpsSvc'=2; }

 Function Indexing {
   $Input | %{ $Index=0 }{$_ | Add-Member INDEX ($Index++) -PassThru} }
   $Esc = ([Char]0x1b)
   
 Switch($OffOnList) 
{
 'Off' 
 { $sParams = @{
   FilePath = 'reg.exe'
   ArgumentList = 
   "Load `"HKLM\Off_Defender`" C:\Windows\System32\Config\System"
   WindowStyle = 'Hidden'; Wait = $True; PassThru = $True }
   $Proc = Start-Process @sParams
    
   If(-Not $Proc.ExitCode) {
   Write-Host "`nSuccessfully [Loaded] HKLM\Off_Defender!" -Fore Blue }
   Else { Throw $Proc.ExitCode }
   
  ForEach($Svc In $DefSvc.GetEnumerator()) {
   If(Test-Path "$RegPE\$($Svc.Key)") {
   Set-ItemProperty -Path "$RegPE\$($Svc.Key)" -Type DWord `
  -Name 'Start' -Value 4 -Force -ErrorAction SilentlyContinue
   Start-Sleep 1
   Get-ItemProperty "$RegPE\$($Svc.Key)" -EA 0 | `
   Select-Object PSChildName,Start,ImagePath } }  
   
   [GC]::Collect()
   [GC]::WaitForPendingFinalizers()
   Start-Sleep 2; Write-Host "`r"
   Reg.exe Unload "HKLM\Off_Defender"
   Write-Host "[UnLoaded] HKLM\Off_Defender!" -Fore Green }

 'On' 
  { ForEach($Svc In $DefSvc.GetEnumerator())
  { Set-ItemProperty -Path "$Reg\$($Svc.Key)" -Type DWord `
	-Name 'Start' -Value "$Reg\$($Svc.Value)" -Force -EA 0
    Start-Sleep 1
	Get-ItemProperty "$Reg\$($Svc.Key)" -EA 0 | `
	Select-Object PSChildName,Start,ImagePath 
	Start-Sleep 1
	Get-ScheduledTask *defender* | Enable-ScheduledTask } }
    
 'List'
 { ($DefSvc.GetEnumerator()).ForEach({
	Get-Service -Name $_.Key }) | Format-Table -Auto | `
	Out-String | %{$_.Trim()};
    $DefSvc.GetEnumerator() | %{ 
    Get-ItemProperty "$Reg\$($_.Key)" -EA 0 } | Indexing | `
	Format-Table INDEX, 
	@{N='Name'; E={"$Esc[38;5;228m$($_.PSChildName)$Esc[0m"}},
	@{N='Start'; E={"$Esc[92m$($_.Start)$Esc[0m"}}, ImagePath }
  Default {}
} 

 If (!([String]::IsNullOrEmpty($Sel))) 
  { $Enum = ($DefSvc.GetEnumerator() | Indexing);
    Set-ItemProperty -Path "$Reg\$($Enum.Name[$Sel])" -Type DWord `
   -Name 'Start' -Value "$($Enum.Value[$Sel])" -EA 0 }
   
<#
# smartscreen
reg add 'HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\AppHost' /v EnableWebContentEvaluation /t REG_DWORD /d 0 /f
Set-ItemProperty `
-Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppHost `
-Name EnableWebContentEvaluation -Type DWord -Value 1 -Force

reg add 'HKEY_CURRENT_USER\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\AppContainer\Storage\microsoft.microsoftedge_8wekyb3d8bbwe\MicrosoftEdge\PhishingFilter' /v EnabledV9 /t REG_DWORD /d 0 /f
reg add 'HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer' /v SmartScreenEnabled /d Off /f
#>
# HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Windows\System EnableSmartScreen (0) 
# HKEY_CURRENT_USER\SOFTWARE\Microsoft\Edge\SmartScreenEnabled default Reg_Dword 1 (edge setting)