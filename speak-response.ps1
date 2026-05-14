# Hook script: speaks Claude's last assistant message via Windows TTS
# Triggered by Claude Code Stop hook, which provides JSON on stdin
# with the field "last_assistant_message"

$ErrorActionPreference = "SilentlyContinue"

$jsonFile = "$env:USERPROFILE\.claude\last_msg.json"
if (-not (Test-Path $jsonFile)) { exit 0 }

try {
    $json = Get-Content $jsonFile -Raw -Encoding UTF8
    $data = $json | ConvertFrom-Json
    $text = $data.last_assistant_message
}
catch { exit 0 }

if (-not $text.Trim()) { exit 0 }

Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.Rate = 1
try { $synth.SelectVoice('Microsoft Xiaoxiao Online') } catch {}
try { $synth.Speak($text) } catch {}
$synth.Dispose()
