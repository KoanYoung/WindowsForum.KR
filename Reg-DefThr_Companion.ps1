$Script:AABM = @{N='AdditionalActionsBitMask'; E={$value = $_.AdditionalActionsBitMask
      Switch([Int]$value) {
        0          {'None'}
        4          {'FullScanRequired'}
        8          {'RebootRequired'}
        12         {'FullScanAndRebootRequired'}
        16         {'ManualStepsRequired'}
        20         {'FullScanAndManualStepsRequired'}
        24         {'RebootAndManualStepsRequired'}
        28         {'FullScanAndRebootAndManualStepsRequired'}
        32768      {'OfflineScanRequired'}
        32772      {'FullScanAndOfflineScanRequired'}
        32776      {'RebootAndOfflineScanRequired'}
        32780      {'FullScanAndRebootAndOfflineScanRequired'}
        32784      {'ManualStepsAndOfflineScanRequired'}
        32788      {'FullScanAndManualStepsAndOfflineScanRequired'}
        32792      {'RebootAndManualStepsAndOfflineScanRequired'}
        default    {"$value"} }} }

$Script:CTESID = @{ Name = 'CurrentThreatExecutionStatusID'; `
Expression = { $value = $_.CurrentThreatExecutionStatusID
      switch([int]$value) {
        0          {'Unknown'}
        1          {'Blocked'}
        2          {'Allowed'}
        3          {'Executing'}
        4          {'NotExecuting'}
        default    {"$value"} }} }

$Script:DSTID = @{ Name = 'DetectionSourceTypeID'; `
Expression = { $value = $_.DetectionSourceTypeID
      switch([int]$value) {
        0          {'Unknown'}
        1          {'User'}
        2          {'System'}
        3          {'RealTime'}
        4          {'IOAV'}
        5          {'NIS'}
		6          {'BHO'}
		6          {'IEProtect'}
        7          {'ELAM'}
        8          {'LocalAttestation'}
        9          {'RemoteAttestation'}
		# Add More Values and Revised
		10         {'AMSI'}
        default    {"$value"} }} }

$Script:TSID = @{ Name = 'ThreatStatusID'; Expression = { $value = $_.ThreatStatusID
      switch([Int]$value) {
        0          {'Unknown'}
        1          {'Detected'}
        2          {'Cleaned'}
        3          {'Quarantined'}
        4          {'Removed'}
        5          {'Allowed'}
        6          {'Blocked'}
		102        {'CleanFailed'}
        103        {'QuarantineFailed'}
        104        {'RemoveFailed'}
        105        {'AllowFailed'}
		106        {'Abandoned'}
        107        {'BlockedFailed'}
        default    {"$value"} }} }

$Script:CAID = @{ Name = 'CleaningActionID'; `
Expression = { $Value = $_.CleaningActionID
      Switch([Int]$Value) {
        0          {'Unknown'}
        1          {'Clean'}
        2          {'Quarantine'}
        3          {'Remove'}
        4          {'Allow'}
		5          {'UserDefined'}
		6          {'Allow'}
		7          {'Block'}
		8          {'ManualStepsRequired'}
		# Add 2 Values
		9          {'NoAction'}
		10         {'Block'}
        Default    {"$Value"} }} }