Param( [Parameter(Mandatory = $False)] [Int]$N = 6 )

Try {

Function ScrollToTop{
	If(!('System.Windows.Forms' -AS [Type])){ Add-Type `
	-AssemblyName 'System.Windows.Forms' }
    [System.Windows.Forms.SendKeys]::SendWait("^{HOME}")
}

Clear-Host
$DetectedThreat = Get-MPThreatDetection | `
Sort-Object InitialDetectionTime -Desc | `
Select-Object -Fir "$N" | ForEach-Object { $index=0 }{ [PSCustomObject] `
@{ Index="[ $([Char]0x1b)[32;1m$($index)$([Char]0x1b)[0m ]"; 
DetectionTime=$_.InitialDetectionTime; Executable=$_.ProcessName; 
DetectionDetails=$_.Resources; 
ThreatID=$_.ThreatID; DetectionID=$_.DetectionID }; $Index++ }

Write-Host ""
Write-Host "`t<가장 최근에 차단된 기록중 $($N)개를 가져옵니다>" -Back Green `
-Fore Black	
Write-Host ""
($DetectedThreat | Format-List | Out-String).Trim()
Start-Sleep 3
& ScrollToTop;

Add-Type -AssemblyName Microsoft.VisualBasic
$Sel = [Microsoft.VisualBasic.Interaction]::InputBox(
    '표시된 Index 넘버를 선택하세요. 
	선택하면 세부정보가 표시됩니다.',
    '차단해제를 원하는 항목 선택')
Try{	
$Proc = Get-Process powershell | `
?{$_.MainWindowTitle -eq '차단해제를 원하는 항목 선택'}	
[Microsoft.VisualBasic.Interaction]::AppActivate($proc.Id) }
Catch{ }
	
$TidSelected = $DetectedThreat.ThreatID[$Sel]
$DetID = $DetectedThreat.DetectionID[$Sel]

If($DetectedThreat.DetectionDetails[$Sel] -Match '^CmdLine:_') {
$File = $DetectedThreat.DetectionDetails[$Sel] -replace '^CmdLine:_'}
ElseIf($DetectedThreat.DetectionDetails[$Sel] -Match '^file:_') {
$File = $DetectedThreat.DetectionDetails[$Sel] -replace '^file:_' }
ElseIf($DetectedThreat.DetectionDetails[$Sel] -Match '^containerfile:_') {
$File = $DetectedThreat.DetectionDetails[$Sel] -replace '^containerfile:_' }
	}

Catch { $_.Error.Exception }

If ([String]::IsNullOrWhiteSpace($Sel)) {
    Return
}
Else {
     [Windows.Forms.MessageBox]::Show( 
	 "위협ID:  $TidSelected  
감지ID:  $DetID 
파일위치:  $File 
를 선택했습니다.", `
     'MESSAGE', [Windows.Forms.MessageBoxButtons]::OK, `
	 [Windows.Forms.MessageBoxIcon]::Asterisk) | Out-Null
     }

$Path = $DetectedThreat[$Sel].Executable | Split-Path -Parent
$EXE = $DetectedThreat[$Sel].Executable | Split-Path -Leaf
$FPath = $File | Split-Path -Parent
$FEXE = $File | Split-Path -Leaf
""
Write-Host "`t< 선택한 위협에 대한 세부내용 >" -Back Green -Fore Black

$result = Get-WinEvent -FilterHashtable `
@{LogName="Microsoft-Windows-Windows Defender/Operational";Id=1117} `
-MaxEvents 50 | ForEach-Object {
    $eventXml = ([xml]$_.ToXml()).Event
    $evt = [Ordered]@{ }
    $evt = [Ordered]@{}
    $eventXml.EventData.ChildNodes | `
	ForEach-Object{ $evt[$_.Name] = $_.'#text' }
	[PsCustomObject]$evt }
    $GotIt = $result | Where-Object {($_."Threat ID" -eq $TidSelected) `
    -and ($_."Detection ID" -eq $DetID)}

[PSCustomObject] @{
	'Product Name' = $GotIt."Product Name"
	'Product Version' = $GotIt."Product Version"
	'Security Intelligence Version' = $GotIt."Security Intelligence Version"
	'Engine Version' = $GotIt."Engine Version"
	'Detection ID' = $GotIt."Detection ID"
    'ThreatID' = $GotIt."Threat ID"
	'Threat Name' = $GotIt."Threat Name"
	'Severity' = $GotIt."Severity Name"
	'Category' = $GotIt."Category Name"
	'Threat Path' = $GotIt.Path
	'Process Name' = $GotIt."Process Name"
	'Detection User' = $GotIt."Detection User"
	'Detection Origin' = $GotIt."Origin Name"
	'Detection Source' = $GotIt."Source Name"
	'Execution Name' = $GotIt."Execution Name"
	'Detection Type' = $GotIt."Type Name"
	'Action Name' = $GotIt."Action Name"
	'Error Code' = $GotIt."Error Code"
	'Error Description' = $GotIt."Error Description"
	'Additional Actions String' = $GotIt."Additional Actions String"
	'Remediation User' = $GotIt."Remediation User"
	'Threat Help Link' = $GotIt.FWLink
	}
	
. "$PSScriptRoot\Reg-DefThr_Companion.ps1"

$1 = Get-CimInstance -ClassName MSFT_MpThreatDetection -Namespace `
root/microsoft/windows/defender | Sort-Object InitialDetectionTime -Desc | 
Select-Object -Fir $N | 
?{ ($_.ThreatID -eq "$TidSelected") -and ($_.DetectionID -eq "$DetID") } | 
Select ActionSuccess, $AABM, $CTESID, $DSTID, $TSID, AMProductVersion, 
$CAID, DetectionID, InitialDetectionTime, LastThreatStatusChangeTime, `
RemediationTime
$2 = Get-CimInstance -ClassName MSFT_MpThreat `
-Namespace root/microsoft/windows/defender | `
Where-Object { $_.ThreatId -eq "$TidSelected" }

$DFProp = [PSCustomObject]@{
	'Is Active?' = $2.IsActive
	'Did Threat Execute?' = $2.DidThreatExecute
	'Action Success' = $1.ActionSuccess
	'Additional Action Need?' = $1.AdditionalActionsBitMask
	'Current Threat Status' = $1.CurrentThreatExecutionStatusID
	'Detection Source Type' = $1.DetectionSourceTypeID
	'Threat Status' = $1.ThreatStatusID
	'Cleaning Status' = $1.CleaningActionID
	'Initial Detect Time' = $1.InitialDetectionTime
	'Last ThreatStatus Change Time' = $1.LastThreatStatusChangeTime
    'Remediation Time' = $1.RemediationTime
	'AntiMalware Product Version' = $1.AMProductVersion}
	
$outLeft  = @(($DFProp| Format-List | Out-String) -split '\r?\n')
$maxLength = ($outLeft | Measure-Object -Property Length -Maximum).Maximum

$result2 = For ($i = 0; $i -lt $outLeft.Count; $i++) {
$left  = If ($i -lt $outLeft.Count) { "{0,-$maxLength}" -f $outLeft[$i] } `
Else { ' ' * $maxLength }; $left }
($result2 | Out-String).Trim()
[System.Windows.Forms.SendKeys]::SendWait("^{End}")

$Response = [System.Windows.Forms.MessageBox]::Show("차단해제 ID로 등록하시겠습니까","등록선택","YesNo","Information","Button1")

If ($Response -eq 'Yes') {
	Try {
   	If (($Path -NotMatch '^([A-Za-z]:\\).*') -OR `
	([String]::IsNullOrWhiteSpace($DetectedThreat.Executable[$Sel]))) {
		
	If ([Bool]($File -replace '^file:_' -match '\.[^.]+$') -eq $TRUE) {
    Add-MpPreference -ExclusionPath $FPath -ExclusionProcess $FEXE -Verbose
    [System.Windows.Forms.MessageBox]::Show("확장자가 있는 차단된 파일이 있어 이것도 차단해제 등록했습니다.") }
	
	ElseIf ([Bool]($File -replace '^CmdLine:_' -match '\.[^.]+$') -eq $TRUE) {
    Add-MpPreference -ExclusionPath $FPath -ExclusionProcess $FEXE -Verbose
    [System.Windows.Forms.MessageBox]::Show("확장자가 있는 차단된 파일이 있어 이것도 차단해제 등록했습니다.") }
	
    Add-MpPreference -ThreatIDDefaultAction_Actions @(6) `
	-ThreatIDDefaultAction_Ids @($TidSelected) -Verbose
    [System.Windows.Forms.MessageBox]::Show("디펜더 설정에 선택한 차단을 해제등록했습니다.") }
	
	Else {
	Add-MpPreference -ThreatIDDefaultAction_Actions @(6) `
	-ThreatIDDefaultAction_Ids @($TidSelected) -ExclusionPath $Path `
	-ExclusionProcess $EXE -Verbose
    [System.Windows.Forms.MessageBox]::Show(`
	"디펜더 설정에 차단해제와 추가로 실행파일위치, 
	실행파일 또한 차단하지 않도록 했습니다.") }
	
	Write-Host ""
	Write-Host "`t< 디펜더 설정에 이렇게 등록됐습니다. >" -Back Green -Fore Black
	Write-Host ""
	Write-Host "`t< ThreatID Default Actions 숫자 설명 >" `
	-Back Green -Fore Black
	Write-Host ""
	Write-Host "`t1-Clean, 2-Quarantine, 3-Remove, 6-Allow" -Fore Blue
	Write-Host "`t8-UserDefined, 9-NoAction, 10-Block" -Fore Blue
	" "
	# Write-Output "`nMicrosoft Defender settings"
    (Get-MpPreference | ForEach-Object {
    [PSCustomObject] @{
	"ThreatID Default Actions" = $_.ThreatIDDefaultAction_Actions | Out-String	
    "Excluded IDs" = $_.ThreatIDDefaultAction_Ids | Out-String
    "Excluded Process" = $_.ExclusionProcess | Out-String
    "Excluded Path" = $_.ExclusionPath | Out-String
    }
    } | Format-List | Out-String).Trim()
	}
	
	Catch { Write-Error -Message '디펜더 등록에 실패했습니다' `
	-Exception $_.Exception }
}
Else { " "; Write-Host "`t차단해제 등록을 취소했습니다" -Back DarkRed `
-Fore Black }