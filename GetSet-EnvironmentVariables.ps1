Function AREnv {
    param(
        [Parameter(Mandatory=$False)]
        [String] $Path = $DFFol.FullName,

        [ValidateSet('Machine', 'User', 'Process')]
        [String] $EType = 'User' )

        $container = @{
            Machine = [EnvironmentVariableTarget]::Machine
            User = [EnvironmentVariableTarget]::User
			Process = [EnvironmentVariableTarget]::Process
        }
		$contType = $container[$EType]
		
		$WholePath = $env:Path -Split ';'
        $DFEnvVer = [RegEx]::Matches($WholePath, '(?<=Windows Defender\\Platform\\).+').Value
		$DFFol = (gci "$env:programdata\Microsoft\Windows Defender\Platform" | Sort {[Version]($_ -replace '[^\d.]')} -desc)[0]
		$DFPrev = $WholePath -match '^(.+\\Windows Defender\\Platform.+)$'
		
        $contType = $container[$EType]
        $EPath = [Environment]::GetEnvironmentVariable('Path', $contType) -split ';'
	
		If ($WholePath -contains $DFPrev) {
		 If (!([Version]($DFFol.Name -replace '[^\d.]') -eq [Version]($DFEnvVer -replace '[^\d.]'))) 
			{
			Write-Host "Detected Defender Previous Version :" -Fore RED
			Write-Host "$DFPrev" -Fore RED
			$EPath = $EPath | Where{ $_ -and $_ -ne $DFPrev }
			[Environment]::SetEnvironmentVariable('Path', $EPath -join ';',
		    $contType)
            Write-Host "$DFPrev" -Fore Magenta 
			Write-Host "Removed From EV." -Fore Magenta
			""
			& ResetEnv 'Path'
			& GetEnv 'User'
            "" }
		}
					
        If ($EPath -Notcontains $Path) {
            $EPath = $EPath + $Path | Where{ $_ }
            [Environment]::SetEnvironmentVariable('Path', ($EPath -join ';'), $contType)
			Write-Host "$($DFFol.FullName)" -Fore Green
			Write-Host "Newly Added to EV." -Fore Green
			""
			& ResetEnv 'Path'
			& GetEnv 'User'
			"" }
		
		ElseIf ($EPath -contains $Path) {
			$EPath = $EPath | Where{ $_ -and $_ -ne $Path }
			[Environment]::SetEnvironmentVariable('Path', ($EPath -join ';'),
		    $contType) 
			Write-Host "$($DFFol.FullName)" -Fore Yellow
			Write-Host "Already Exists In EV." -Fore Yellow
			""
			Write-Host "This is Your Latest Defender Folder Version Include With mpcmdrun.exe"
			Write-Host "$($DFFol.FullName)" -Fore Yellow
			}
}	

Function GetEnv {
    param(
        [Parameter(Mandatory=$true)]
        [ValidateSet('Machine', 'User','Process')]
        [string] $Container
    )

    $cMapping = @{
        Machine = [EnvironmentVariableTarget]::Machine
        User = [EnvironmentVariableTarget]::User
		Process = [EnvironmentVariableTarget]::Process
    }
    $cType = $cMapping[$Container]

    [Environment]::GetEnvironmentVariable('Path', $cType) -split ';' | Where { $_ }
}

Function ResetEnv {
    Set-Item -Path (('Env:', 'Path') -join '') -Value ((
            [System.Environment]::GetEnvironmentVariable('Path', 'Machine'),
            [System.Environment]::GetEnvironmentVariable('Path', 'User')
        ) -join ';')
}

# Export-ModuleMember -Function *

<#
$path = [System.Environment]::GetEnvironmentVariable('PATH','User')
$path = ($path.Split(';') | Where-Object { $_ -ne 'ValueToRemove' }) -join ';'
[System.Environment]::SetEnvironmentVariable('PATH',$path,'User')
#>