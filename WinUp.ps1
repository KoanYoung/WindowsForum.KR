  Param([Switch]$Detail, [Switch]$Hide, [Switch]$NoHide)
  Clear-Host
  Function Get-WinUpdate { 
      $USvcMgr = New-Object -ComObject 'Microsoft.Update.ServiceManager'
	  $SList = $USvcMgr.Services
	
  If (-Not($SList | ?{$_.Name -Match 'Microsoft Update'}).IsDefaultAUService)
     {$USvcMgr.AddService2("7971f918-a847-4430-9279-4a52d1efe18d",7,"")
	  Write-Host "`t`t업데이트 서버는 [Microsoft Update]로 등록했습니다.`n" `
	 -Back DarkGreen -Fore Black}
	   
  Try {
	   $USession = New-Object -ComObject 'Microsoft.Update.Session'
       $USearcher = $USession.CreateUpdateSearcher()
	   $USearcher.IncludePotentiallySupersededUpdates = $True
	   $USearcher.Online = $True
	   $USearcher.SearchScope = 3
       $SResult = $USearcher.Search("DeploymentAction=* and IsInstalled=0")
		
    If([String]::IsNullOrEmpty($($SResult.Updates))){
       Write-Host "`a`t`t지금은 업데이트 할게 없습니다." -fore RED }
	Else { $SResult.Updates; 
	  ForEach($EachVar In $SResult.Updates) {
	   Switch($EachVar.MaxDownloadSize)
	   { {[System.Math]::Round($_ / 1KB,2) -lt 1024} { $size =`
	   [String]([System.Math]::Round($_ / 1KB,2))+" KB"; break }
	   {[System.Math]::Round($_ / 1MB,2) -lt 1024} { $size =`
		[String]([System.Math]::Round($_ / 1MB,2))+" MB"; break }  
	   {[System.Math]::Round($_ / 1GB,2) -lt 1024} { $size =`
		[String]([System.Math]::Round($_ / 1GB,2))+" GB"; break }    
	   Default { $size = $_+" B" } } 
	   
	   Add-Member -InputObject $EachVar -MemberType NoteProperty `
	   -Name Size -Value $size } }
      }
  Catch { Write-Error $_.Error.Message }
	}
	  
    $AutoSel = @{N='AutoSelection'; E={$AS = $_.AutoSelection
    Switch($AS) { 0 {'윈도우 업데이트가 알아서 선택'} `
	1 {"$ESC[93m다운로드되면 자동선택$ESC[0m"} 2 {'항상 자동선택 안함'}
	3 {'항상 자동선택'} Default {$AS} }}}

    $AutoDown = @{N='AutoDownload'; E={$AD = $_.AutoDownload
    Switch($AD) { 0 {'윈도우 업데이트가 알아서 선택'} 1 {'항상 자동다운로드 안함'}
	2 {"$ESC[93m항상 자동다운로드$ESC[0m"} Default {$AD} }}}

    $DeployAct = @{N='DeploymentAction'; E={$DA = $_.DeploymentAction
    Switch($DA) { 0 {'None'} 1 {'Installation'} 2 {'Uninstallation'} 
	3 {'Detection'} 4 {'Optional Feature'} Default {$DA} }}}

    $DownPrior = @{N='DownloadPriority'; E={$DP = $_.DownloadPriority
    Switch($DP) { 1 {'Low'} 2 {'Normal'} 3 {'High'} 4 {'ExtraHigh'}
	Default {$DP} }}}

    $UpType = @{N='UpdateType'; E={$UT = $_.Type
    Switch($UT) { 1 {'Software'} 2 {'Driver'} Default {$UT} }}}

	$BrowseOnly = @{N='BrowseOnly'; E={$BO = $_.BrowseOnly
	Switch($BO) { $True {"$ESC[93mOptional$ESC[0m"} $False {'Non-Optional'}
	Default {} }}}

    $ESC = [Char]27
 If ($Detail.IsPresent) {
     Clear-Host
     Write-Host "`n`t`t[Microsoft Update] 서버에 연결합니다...`n" `
     -Back DarkGreen -Fore Black
     
	 $WU = Get-WinUpdate
     $WU | Format-List `
     @{N='Index'; E={"$ESC[97m$($WU.IndexOf($_))$ESC[0m"}},
	 @{N='IsHidden'; E={ If($($_.IsHidden)) {"$ESC[91m[숨김]$ESC[0m"}
	                     Else{"$ESC[92m[보임]$ESC[0m"} }},
     @{N='Category'; E={"$($_.Categories._NewEnum.Name)"}},				
	 @{N='KB'; E={"$($_.KBArticleIDs)"}},
     @{N='Title'; E={"$ESC[92m$($_.Title)$ESC[0m"}}, 
	 Description,
	 @{N='MaxSize'; E={"$ESC[36m$($_.Size)$ESC[0m" }},
	 $AutoDown, $AutoSel, $DeployAct, $DownPrior, $UpType,
     @{N='AutoSelectByWindowsUpdate';
	 E={ If($($_.AutoSelectOnWebsites)) {"$ESC[93mTrue$ESC[0m"}
	     Else{"False"} }},
     @{N='MsrcSeverity'; E={"$ESC[93m$($_.MsrcSeverity)$ESC[0m"}},
     @{N='UpdateID'; E={"$($_.Identity.UpdateID)"}}, $BrowseOnly,
     @{N='LastDeploymentChangeTime';
	 E={"$ESC[36m$($_.LastDeploymentChangeTime)$ESC[0m" }},
	 DriverClass, DriverHardwareID, DriverManaufacturer,
     @{N='DriverModel'; E={"$ESC[92m$($_.DriverModel)$ESC[0m"}},
     DriverProvider, IsPresent, IsDownloaded, IsInstalled,
     IsMandatory, EulaAccepted
    }

 Else{  
	 Write-Host "`n`t`t[Microsoft Update] 서버에 연결합니다...`n" `
     -Back DarkGreen -Fore Black 
	 $stopWatch = [system.diagnostics.stopwatch]::startNew()
	 
	 $WU = Get-WinUpdate
	 $WU | Format-List `
	 @{N='Index'; E={"$ESC[97m$($WU.IndexOf($_))$ESC[0m"}},
	 @{N='Category'; E={"$ESC[97m$($_.Categories._NewEnum.Name)$ESC[0m"}},
	 @{N='IsHidden'; E={ If($($_.IsHidden)) {"$ESC[91m[숨김]$ESC[0m"}
	                     Else{"$ESC[92m[보임]$ESC[0m"}}},
     @{N='MsrcSeverity'; E={"$ESC[93m$($_.MsrcSeverity)$ESC[0m"}},			 
	 @{N='MaxSize'; E={"$ESC[36m$($_.Size)$ESC[0m" }},
	 @{N='Title'; E={"$ESC[97m$($_.Title)$ESC[0m"}}, Description |
	 Out-String | %{$_.Trim()}
	 
	 [Int]$Elapsed = $stopWatch.Elapsed.TotalSeconds
	 "`n`t`t`a✅ 검색시간은 $elapsed 초 걸렸습니다.`n" 
	 
 If ($Hide) { 
	 Write-Host "`n[숨기려는 업데이트" -NoNewLine
     Write-Host " Index 숫자" -Fore Red -NoNewLine 
	 Write-Host "를 입력하세요]: " -NoNewLine
     [Int[]]$CInput = (Read-Host).ForEach({$_}) -split ' '; "`n"
	 ($WU[$CInput]).ForEach({$_.IsHidden = $True; $_.AcceptEula()}) 
	 Write-Host "업데이트를 [숨김] 으로 했습니다.`n" -Fore Red
     Write-Output $WU[$CInput].Title; Write-Host "" }
		  	  
 If ($NoHide) { 
	 Write-Host "`n[숨김해제 하려는 업데이트" -NoNewLine
     Write-Host " Index 숫자" -Fore Green -NoNewLine 
	 Write-Host "를 입력하세요]: " -NoNewLine
	 [Int[]]$CInput = (Read-Host).ForEach({$_}) -split ' '; "`n"
     ($WU[$CInput]).ForEach({ $_.IsHidden = $False })			  
	 Write-Host "업데이트를 [보임] 로 했습니다.`n" -Fore Green
	 Write-Output $WU[$CInput].Title; "`n" }
} 
	 [System.GC]::Collect()
     [System.GC]::WaitForPendingFinalizers()
	  
	  