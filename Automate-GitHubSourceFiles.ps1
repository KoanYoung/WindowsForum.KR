<#
Function DGit-Zip {
    [CmdletBinding()]
    Param( 
	    # $GHRepo,
        # $Branch="master"
        #[Parameter(ValueFromPipelineByPropertyName)]
        #$ProjectUri
    )
#>	
<#
    Process {
     if($PSBoundParameters.ContainsKey("ProjectUri")) {
        $GHRepo=$null
        if($ProjectUri.OriginalString.StartsWith("https://github.com")) {
           $GHRepo=$ProjectUri.AbsolutePath } 
		else {
             $name=$ProjectUri.LocalPath.split('/')[-1]
             Write-Host -ForegroundColor Red ("Module [{0}]: not installed, it is not hosted on GitHub " -f $name)
            }
        }
#>
    Set-Clipboard;
	$Branch = 'master'
    $proc = Get-Process firefox | ?{$_.MainWindowTitle -ne ''}
    If(!('System.Windows.Forms' -AS [Type])){ 
    Add-Type -AssemblyName 'System.Windows.Forms'
    Add-Type -AssemblyName 'Microsoft.VisualBasic' }
	
    [Microsoft.VisualBasic.Interaction]::AppActivate($proc.Id)
    [Windows.Forms.SendKeys]::SendWait("%{d}")
	[Windows.Forms.SendKeys]::SendWait("^{c}")
	
	$copiedUrl = Get-Clipboard
	$FilteredUrl = $copiedUrl.Split('/')[-2,-1] -Join '/'
	Start-Sleep 2
	
	Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class SFW {
    [DllImport("user32.dll")]
    [return: MarshalAs(UnmanagedType.Bool)]
    public static extern bool SetForegroundWindow(IntPtr hWnd); }
"@
    $fw = (get-process WindowsTerminal).MainWindowHandle[0]
    [Void][SFW]::SetForegroundWindow($fw)

    If($FilteredUrl) {
    Write-Host ("[$(Get-Date)] Retrieving {0} {1}" `
	-f $FilteredUrl, $Branch) -Fore Green
    $Url = "https://github.com/{0}/archive/{1}.zip" -f $FilteredUrl, $Branch
	   
	# $OutFile="$($pwd)\$($Branch).zip"
	# $OutFile="$($pwd)\$($GHRepo.split('/')[1]).zip"
				
	$Out = "$($PWD)\$($FilteredUrl -Replace('/','-')).zip"
	Invoke-RestMethod $Url -OutFile $Out
    Unblock-File $Out
    Expand-Archive -Path $Out -Dest $PWD -Force
	# Remove-Item $Out -ver
	$Dest = "$env:OD\Codes"
	$Num = 1
	Get-ChildItem . -directory | Sort-Object -desc -prop LastWriteTime | `
	Select-Object -fir 1 | `
	%{ $newName = Join-Path $Dest -childPath $_.Name; `
	While(Test-Path -path $newName) {$newName = Join-Path $Dest `
	($_.baseName + "_$Num"); $Num += 1} $_ | `
	Move-Item -dest $newName -force -ver }
}