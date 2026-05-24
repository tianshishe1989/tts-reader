# Called by Claude Code Stop hook
# Reads stdin JSON, saves it, launches TTS in background
$pidFile = "$env:USERPROFILE\.claude\tts_pid.txt"

[Console]::InputEncoding = [Text.Encoding]::UTF8
$json = [Console]::In.ReadToEnd()
[IO.File]::WriteAllText("$env:USERPROFILE\.claude\last_msg.json", $json, [Text.Encoding]::UTF8)

# Kill previous TTS process if still running (prevents overlapping speech)
if (Test-Path $pidFile) {
    try {
        $oldPid = [int](Get-Content $pidFile -Raw)
        $oldProc = Get-Process -Id $oldPid -ErrorAction SilentlyContinue
        if ($oldProc -and $oldProc.ProcessName -eq 'powershell') {
            $oldProc | Stop-Process -Force -ErrorAction SilentlyContinue
        }
    } catch {}
}

# Launch new TTS, save its PID
$proc = Start-Process powershell -WindowStyle Hidden -PassThru -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File',"$env:USERPROFILE\scripts\speak-response.ps1"
if ($proc) {
    $proc.Id | Out-File -FilePath $pidFile -NoNewline
}
