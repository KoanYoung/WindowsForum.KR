$mp3Path = "$Env:UserProfile\Downloads\startup.mp3"
$Mplayer = 
[Windows.Media.Playback.MediaPlayer,Windows.Media,ContentType=WindowsRuntime]::New()
$MPlayer.Source = 
[Windows.Media.Core.MediaSource]::CreateFromUri($mp3Path)
$MPlayer.Play()