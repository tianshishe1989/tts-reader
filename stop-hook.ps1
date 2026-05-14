# Called by Claude Code Stop hook
# Reads stdin JSON, saves it, launches TTS in background
[Console]::InputEncoding = [Text.Encoding]::UTF8
$json = [Console]::In.ReadToEnd()
[IO.File]::WriteAllText("$env:USERPROFILE\.claude\last_msg.json", $json, [Text.Encoding]::UTF8)

Start-Process powershell -WindowStyle Hidden -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"$env:USERPROFILE\scripts\speak-response.ps1"
