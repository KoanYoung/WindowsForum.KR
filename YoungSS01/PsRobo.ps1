<#
$Source = "'$($args[0])'"
$Destination = "'$($args[1])'"
#>

Param([Parameter(Position = 0)][String] $Source, 
      [Parameter(Position = 1)][String] $Destination)
<#	  
$robocmd = "robocopy " + $Source + " " + $Destination +  " /E /BYTES /mt /XF sync.ffs_db /R:1 /W:1 /DCOPY:DAT /COPYALL"
$staging = invoke-expression "$robocmd /l"
#>

$robocmd = @($Source, $Destination) + `
"/E /BYTES /mt /XF sync.ffs_db /R:1 /W:1 /DCOPY:DAT /COPYALL".Split(" ")
$staging = invoke-expression "robocopy $robocmd /l"

$ttnewfile=$staging -match 'new file'
$ttmodified = $staging -match 'newer'
$totalfile = $ttnewfile + $ttmodified   
$ttBytearray = [System.Collections.ArrayList]@()
foreach ($file in $totalfile)
{
$arrayID = $ttBytearray.add($file.substring(13,13).trim()) 
}
$totalByte = (($ttBytearray | measure-object -sum).sum)

<#
$robocopyjob = Start-Job -Name robocopy -ScriptBlock {param ($command) ; Invoke-Expression -Command $command} -ArgumentList $robocmd 
#>

$robocopyJob = Start-Job -Name Robo1 -scriptBlock { robocopy $using:robocmd }

<#
while ($robocopyjob.State -eq 'running')
{
$progress = Receive-Job -Job $robocopyjob -Keep -ErrorAction SilentlyContinue
} 
#>

While(($robocopyJob.HasMoreData) -OR ($robocopyJob.State -eq "Running")) 
{ 
  $progress += (Receive-job $robocopyJob)
  Start-Sleep 1	

$totolFileCount = $totalfile.count
if ($progress)
{
$copiedfiles = ($progress | Select-String -SimpleMatch 'new file', 'newer')
            if ($copiedfiles) 
            {
            if ($copiedfiles.count -le 0) { $TotalFilesCopied = $copiedfiles.Count }
			
			<# else { $TotalFilesCopied = $copiedfiles.Count - 1 } #>
            else { $TotalFilesCopied = $copiedfiles.Count }
		   
            $FilesRemaining = ($totalfile.count - $TotalFilesCopied)
            $Bytesarray = [System.Collections.ArrayList]@()
            foreach ($Newfile in $copiedfiles)   
            {
                if($Newfile)
                {
                $curCopy =  $Bytesarray.add($Newfile.tostring().substring(13, 13).trim())
                }
            }
            $TotalCopies = (($Bytesarray | measure-object -sum).sum)
			$PercentComplete = (($TotalCopies/$totalByte) * 100)
			
			<#
            Write-Progress -Id 1 -Activity "Backup files, $TotalFilesCopied of $totolFileCount  " -Status "status" -PercentComplete $PercentComplete
            }
			#>
			
            Write-Progress -Id 1 -Activity `
			"TotalSize [$([Math]::Round($Totalbyte/1GB,2))GB] $TotalFilesCopied / $totolFileCount - $FilesRemaining Remaining  $Source >> $Destination " `
			-Status "status" -PercentComplete $PercentComplete
            }			
}
}

<#
Write-Progress -Id 1 -Activity "Copying files from $Source to $Destination" -Status 'Completed' -Completed 
#>

<#
$results = Receive-Job -Job $robocopyjob 
Remove-Job $robocopyjob
$results[5] 
$results[-13..-1] 
$args[0]
$args[1]
$Source
$Destination
cmd /c pause | out-null
#>

Get-Job | Remove-Job
Write-Host "`n"
$progress[5] 
$progress[-13..-1] 
$args[0]
$args[1]
$Source
$Destination
cmd /c pause | out-null
