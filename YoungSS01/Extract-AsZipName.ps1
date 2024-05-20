$FPath = (Resolve-Path .\Temp1).Path
(gci -file).Where({$_.Extension -match '(nupkg|zip)'}) |`
move-item -dest $FPath -v

ForEach ($file in (gci .\Temp1\* -File )) { 
    $FolAsZipName = Join-Path $FPath $file.BaseName
    If (!(Test-Path $FolAsZipName -PathType Container)) {
        $Null = New-Item -ItemType Directory -Path $FolAsZipName
    }
    & 7z x $file.FullName -o"$FolAsZipName" -aoa -y
	}
