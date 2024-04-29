Start-Service -Name TrustedInstaller
$parent = Get-NtProcess -ServiceName TrustedInstaller
$proc = New-Win32Process powershell.exe -CreationFlags NewConsole -ParentProcess $parent
$proc.Process.User