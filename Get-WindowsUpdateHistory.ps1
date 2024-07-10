	Param([Switch]$Def)	
			
	Clear-Host	
        $UpdateCollection = @()
        $objSession =  [Activator]::CreateInstance(`
		[Type]::GetTypeFromProgID("Microsoft.Update.Session"))
        $objSearcher = $objSession.CreateUpdateSearcher()
        $objSearcher.IncludePotentiallySupersededUpdates = $true
        $objSearcher.Online = $true
        $TotalHistoryCount = $objSearcher.GetTotalHistoryCount()

    If($TotalHistoryCount -gt 0)
     { 
        $objHistory = $objSearcher.QueryHistory(0, $TotalHistoryCount)
	    $NumberOfUpdate = 1;
		
        Foreach($obj in $objHistory)
	    { Write-Progress -Activity "[UPDATE HISTORY]" `
	   -Status "[$NumberOfUpdate/$TotalHistoryCount] $($obj.Title)" `
	   -PercentComplete ([Int]($NumberOfUpdate/$TotalHistoryCount * 100))
		
        $ESC = [Char]27		
		$NumberOfUpdate++
	    $matches = $Null
		$obj.Title -Match "(KB\d+)" | Out-Null
		
		If($matches -eq $Null) 
		  { Add-Member -InputObject $obj -MemberType NoteProperty -Name KB -Value "$ESC[33m[No KB]$ESC[0m" } 
		
		Else 
		  { Add-Member -InputObject $obj -MemberType NoteProperty -Name KB -Value "$ESC[93m$($matches[0])$ESC[0m" }	
		
		If ($Def.IsPresent) {
		$UpdateCollection += $obj }
		
		Else {
		$UpdateCollection += $obj | ?{$_.Title -notMatch '^(Security Intelligence Update)'}}
	    }
	    	
		$UpdateCollection | Sort-Object -prop { $_.Date } | Format-List `
		@{N = 'Index'; E = {`
		"$ESC[97m$($UpdateCollection.IndexOf($_))$ESC[0m"}}, KB, `
		@{Name = 'Operation'; Expression = { `
        Switch ($_.Operation) { 
	           1 {'Installation'}
	           2 {'Uninstallation'}
	           3 {'Others'} } } },
        @{Name = 'Status'; Expression = { `
        Switch ($_.ResultCode) { 
	           0 {"$ESC[90mNot Started$ESC[0m"} 
	           1 {"$ESC[30;47mIn Progress$ESC[0m"} 
	           2 {"$ESC[92mSuccess$ESC[0m"} 
	           3 {"$ESC[33mIncompleted$ESC[0m"} 
	           4 {"$ESC[91mFailed$ESC[0m"}
	           5 {"$ESC[95mAborted$ESC[0m"} } } },
		@{N = 'Date'; E = {"$ESC[36m$($_.Date)$ESC[0m"}},
		@{N = 'Title'; E = {"$ESC[32m$($_.Title)$ESC[0m"}},
		@{N = 'Desc'; E = {$_.Description}},
		@{N = 'AppID'; E = {$_.ClientApplicationID}},
		@{N = 'UninsNotes'; E = {"$($_.UninstallationNotes)"}},
		@{N = 'UpdateID'; E = {"$ESC[97m$($_.UpdateIdentity.UpdateID)$ESC[0m"}}
     }
	
	Else { Write-Warning "아마 업데이트 기록이 지워진거 같습니다." } 
		
		If ($Def.IsPresent) {
		Write-Host "`t총 업데이트된 갯수: $($TotalHistoryCount)개" `
        -Back DarkGreen -Fore Black
        }		
			
		Else {	
        Write-Host "`t총 업데이트된 갯수: $($TotalHistoryCount)개" `
        -Back DarkGreen -Fore Black
        Write-Host "`t디펜더 정의 업데이트 갯수: $($TotalHistoryCount - $($UpdateCollection.Count))개" -Back DarkGreen -Fore Black
		Write-Host ""
        Write-Host "`t위에 표시된 업데이트 갯수: $($UpdateCollection.Count)개" `
		-Back Blue -Fore Black
		Write-Host `
		"`t(양이 많은 디펜더 정의 업데이트는 제외한 수)" `
		-Back Blue -Fore Black
		}
		
      [Runtime.Interopservices.Marshal]::ReleaseComObject($objSession) | Out-Null
      [Runtime.Interopservices.Marshal]::ReleaseComObject($objSearcher) | Out-Null
      [System.GC]::Collect()
      [System.GC]::WaitForPendingFinalizers()	
