 Param ( [Parameter(Mandatory)] [String]$URL,
         [Parameter(Mandatory)] [String]$File )
 Begin {
  Function Show-Progress { 
    Param ( [Parameter(Mandatory)] [Single]$TotalValue,
            [Parameter(Mandatory)] [Single]$CurrentValue,
            [Parameter(Mandatory)] [String]$ProgText,
            [String]$Suffix,
            [Int]$BarSize = 40,
            [Switch]$Complete )
            
       $percent = $CurrentValue / $TotalValue
       $percentComplete = $percent * 100
	   $curBarSize = $BarSize * $percent
       $progbar = ""
       $progbar = $progbar.PadRight($curBarSize,[Char]9608)
	   $progbar = $progbar.PadRight($BarSize,[Char]9617)
        
	   If (!$Complete.IsPresent) {		   
       Write-Host -NoNewLine "`r$ProgText $progbar [ $($CurrentValue.ToString("#.###").PadLeft($TotalValue.ToString("#.###").Length))$Suffix / $($TotalValue.ToString("#.###"))$Suffix ] $($percentComplete.ToString("##0.00").PadLeft(6)) % 완료"
       [Console]::CursorVisible=$False }
	   
       Else {	   
       Write-Host -NoNewLine "`r$ProgText $progbar [ $($TotalValue.ToString("#.###").PadLeft($TotalValue.ToString("#.###").Length))$Suffix / $($TotalValue.ToString("#.###"))$Suffix ] $($percentComplete.ToString("##0.00").PadLeft(6)) % 완료"
	   }	   
    } }		
 Process {
  Try {
       $ErrorActionPreference = 'Stop'        
       $request = [System.Net.HttpWebRequest]::Create($URL)
       $response = $request.GetResponse()
  
   If ([Int]$response.StatusCode -ne 200)
	 { Throw "파일이 없거나,엑세스 권한이 없거나, 또는 '$URL' 에 접근금지 돼있습니다." }
     
   If ($File -match '^\.\\') {
       $File = Join-Path ($(Get-Location).Path) ($File -Split '^\.')[1] }
	   
   If ($File -and !(Split-Path $File)) {
       $File = Join-Path $((Get-Location).Path) $File }
   
   If ($File) {
        $fileDirectory = $([System.IO.Path]::GetDirectoryName($File))
     If (!(Test-Path $fileDirectory)) {
        [System.IO.Directory]::CreateDirectory($fileDirectory) | Out-Null } }
     
		[Long]$fullSize = $response.ContentLength
        $fullSizeMB = $fullSize / 1024 / 1024
        [Byte[]]$buffer = New-Object Byte[] (4096*1024)
        [Long]$total = [Long]$count = 0
  
        $reader = $response.GetResponseStream()
        $writer = New-Object System.IO.FileStream $File,"Create"
  
       # $finalBarCount = 0
      Do {
         $count = $reader.Read($buffer, 0, $buffer.Length)
         $writer.Write($buffer, 0, $count)
         $CurrTotal += $count
         $CurrMB = $CurrTotal / 1024 / 1024
          
        If ($fullSize -gt 0) {
           Show-Progress -TotalValue $fullSizeMB `
		   -CurrentValue $CurrMB -ProgText "다운로드중" -Suffix " MB" }

           <# -and $finalBarCount -eq 0 #>
        If ($CurrTotal -eq $fullSize -and $count -eq 0 )
		   {
           Show-Progress -TotalValue $fullSizeMB -CurrentValue $CurrMB `
		   -ProgText "다운로드완료" -Suffix "MB" -Complete
		   }
           # $finalBarCount++
        } While ($count -gt 0)
      }
  
   Catch { $ExceptionMsg = $_.Exception.Message
           Write-Host "`nDownload breaks with error : $ExceptionMsg" }
  
 Finally { If ($reader) { $reader.Close() }
           If ($writer) { $writer.Flush(); $writer.Close() }
           $ErrorActionPreference = 'Stop'
           [GC]::Collect() }    
    }