Param([String]$OnOff)

   $DefRegPE = "HKLM:\Off_Defender\ControlSet001\Services"
   $DefReg = "HKLM:\System\CurrentControlSet\Services"
   $DefSvc = 
   [Ordered] @{'MpsDrv'=3; 'MdCoreSvc'=2; 'MpsSvc'=2; `
   'SecurityHealthService'=3; 'Sense'=3; 'WpcMonSvc'=3; 'WdBoot'=0; `
   'WdFilter'=0; 'WdNisDrv'=3; 'WdNisSvc'=3; 'WscSvc'=2; 'WinDefend'=2 }

 Switch($OnOff) {
  'Off' 
 { $sParams = @{
   FilePath     = 'reg.exe'
   ArgumentList =
   "Load `"HKLM\Off_Defender`" `"C:\Windows\System32\Config\System`""
   WindowStyle  = 'Hidden'; Wait = $True; PassThru = $True }
   $Proc = Start-Process @sParams
    
   If(-Not $Proc.ExitCode) {
   Write-Host "Successfully " -NoNewLine -Fore Blue 
   Write-Host "[Loaded] HKLM\Off_Defender!" }
   Else { Throw $Proc.ExitCode }
   
 ForEach($Svc In $DefSvc.GetEnumerator()) 
  {
  If(Test-Path "$DefRegPE\$($Svc.Key)") 
   { 
    Set-ItemProperty -Path "$DefRegPE\$($Svc.Key)" -Type DWord `
	-Name 'Start' -Value 4 -Force -ErrorAction SilentlyContinue
    Start-Sleep 1
    Get-ItemProperty "$DefRegPE\$($Svc.Key)" -EA 0 | `
	Select-Object PSChildName,Start,ImagePath 
   } } 
   
   Write-Host ""
   [GC]::Collect()
   [GC]::WaitForPendingFinalizers()
   Start-Sleep 2
   Reg.exe Unload "HKLM\Off_Defender"
   Write-Host "[UnLoaded] " -Fore Green -NoNewLine
   Write-Host "HKLM\Off_Defender!`n`r"
 }

  'On' 
 { ForEach($Svc In $DefSvc.GetEnumerator())
  { Set-ItemProperty -Path "$DefReg\$($Svc.Key)" -Type DWord `
	-Name 'Start' -Value "$DefReg\$($Svc.Value)" -Force -EA 0
    Start-Sleep 1
	Get-ItemProperty "$DefReg\$($Svc.Key)" -EA 0 | `
	Select-Object PSChildName,Start,ImagePath }
 }
 Default { ForEach($Svc In $DefSvc.GetEnumerator()) 
  { Get-ItemProperty "$DefReg\$($Svc.Key)" -EA 0 | `
    Select-Object PSChildName,Start,ImagePath }
 } }