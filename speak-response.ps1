# Hook script: speaks Claude's last assistant message via Windows TTS
# Triggered by Claude Code Stop hook, which provides JSON on stdin
# with the field "last_assistant_message"
#
# v2: Sentence-by-sentence async playback — handles very long responses
#     without blocking or timing out.

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

# --- Strip Markdown formatting ---
$text = $text -replace '\*\*(.+?)\*\*', '$1'      # **bold**
$text = $text -replace '\*(.+?)\*', '$1'           # *italic*
$text = $text -replace '__(.+?)__', '$1'           # __bold__
$text = $text -replace '_(.+?)_', '$1'             # _italic_
$text = $text -replace '`(.+?)`', '$1'             # inline code
$text = $text -replace '\[(.+?)\]\(.+?\)', '$1'    # [link](url)
$text = $text -replace '(?m)^#{1,6}\s+', ''         # headings
$text = $text -replace '(?m)^>\s+', ''              # blockquote
$text = $text -replace '(?m)^[-*_]{3,}\s*$', ''     # horizontal rules
$text = $text -replace '```[\s\S]*?```', ''         # code blocks
$text = $text -replace '~~~[\s\S]*?~~~', ''         # code blocks (tilde)
$text = $text -replace '\|.*?\|', ''                # table rows
$text = $text -replace '(?m)^[-| ]{3,}\s*$', ''     # table separators

# --- Split into sentences for responsive playback ---
$sentences = [regex]::Split($text.Trim(), '(?<=[.!?。！？\n])\s*') | Where-Object { $_.Trim() }
if (-not $sentences -or $sentences.Count -eq 0) {
    $sentences = @($text.Trim())
}

# --- Speak sentence by sentence (async, cancellable) ---
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.Rate = 1
try { $synth.SelectVoice('Microsoft Xiaoxiao Online') } catch {}

foreach ($sentence in $sentences) {
    $trimmed = $sentence.Trim()
    if (-not $trimmed) { continue }

    try {
        $task = $synth.SpeakAsync($trimmed)
        while (-not $task.IsCompleted) {
            Start-Sleep -Milliseconds 100
        }
    }
    catch {
        # If cancelled mid-speech, stop gracefully
        break
    }
}

$synth.Dispose()
