 Param([String]$OffOnList, [String]$Sel)

  $RegPE = "HKLM:\Off_Defender\ControlSet001\Services"
  $Reg = "HKLM:\System\CurrentControlSet\Services"
  $SmartS = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer'
  $SmartsPE = `
  'Registry::HKU\Off_SmartS\Microsoft\Windows\CurrentVersion\Explorer'
  . "$PSScriptRoot\Out-HostColored.ps1"

  $DefSvc = [Ordered] @{
  'SecurityHealthService'=3; 'Sense'=3; 'WpcMonSvc'=3; 'WdBoot'=0;
  'WdFilter'=0; 'WdNisDrv'=3; 'WdNisSvc'=3; 'WscSvc'=2;
  'WinDefend'=2; 'MdCoreSvc'=2; 'SgrmAgent'=0; 'SgrmBroker'=2; 
  'MsSecCore'=0; 'MsSecFlt'=3; 'webthreatdefsvc'=3 }

 Function Indexing {
   $Input | %{ $Index=0 }{$_ | Add-Member INDEX ($Index++) -PassThru} }
   $Esc = ([Char]0x1b)
   
 Switch($OffOnList) 
{
 'Off' 
 { Try{ 
   Reg.exe Load HKLM\Off_Defender "C:\Windows\System32\Config\System"
   Reg.exe Load HKU\Off_SmartS "C:\Windows\System32\Config\Software"
   Write-Host "`n[Loaded] HKLM\Off_Defender" -Fore Blue
   Write-Host "[Loaded] HKU\Off_SmartS" -Fore Blue }
   Catch { Throw }
   
   Set-ItemProperty -path $SmartsPE -Name 'SmartScreenEnabled' `
   -Value 'Off' -Force -Ver
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
   Reg.exe Unload HKLM\Off_Defender
   Reg.exe Unload HKU\Off_SmartS
   Write-Host "[UnLoaded] HKLM\Off_Defender!" -Fore Green
   Write-Host "[Unloaded] HKU\Off_SmartS!" -Fore Green }

 'On' 
  { Set-ItemProperty -path $SmartS -Name 'SmartScreenEnabled' `
   -Value 'On' -Force -Ver
 ForEach($Svc In $DefSvc.GetEnumerator())
  { Set-ItemProperty -Path "$Reg\$($Svc.Key)" -Type DWord `
   -Name 'Start' -Value "$($Svc.Value)" -Force -EA 0
    Start-Sleep 1
	Get-ItemProperty "$Reg\$($Svc.Key)" -EA 0 | `
    Select-Object PSChildName,Start,ImagePath }
	Start-Sleep 1
	Get-ScheduledTask *defender* | Enable-ScheduledTask | Out-String |`
    %{$_.TrimEnd()} }
    
 'List'
 {  $DefSvc.Add('MpsDrv',3); $DefSvc.Add('MpsSvc',2);
   ($DefSvc.GetEnumerator()).ForEach({
    Get-Service -Name $_.Key}) | Format-Table Status, Name,
	@{N='Start'; E={$_.StartType}}, DisplayName `
	| Out-String | %{$_.Trim("`r","`n")} | `
	Out-HostColored `
	@{'Running'='Green'; 'Manual'='Green'; 'Automatic'='Green'; 
	'Disabled'= 'Red'}
	
    $DefSvc.GetEnumerator() | %{ 
    Get-ItemProperty "$Reg\$($_.Key)" -EA 0 } | Indexing | `
	Format-Table INDEX, 
	@{N='Name'; E={"$Esc[38;5;228m$($_.PSChildName)$Esc[0m"}},
	@{N='Start'; E={If($_.Start -eq 4){"$Esc[91m$($_.Start)$Esc[0m"}
	                Else{"$Esc[92m$($_.Start)$Esc[0m"}}}, ImagePath }
 'Default' {}
} 

 If (!([String]::IsNullOrEmpty($Sel))) 
  { $Enum = ($DefSvc.GetEnumerator() | Indexing);  
    Set-ItemProperty -Path "$Reg\$($Enum.Name[$Sel])" -Type DWord `
   -Name 'Start' -Value "$($Enum.Value[$Sel])" -EA 0 }