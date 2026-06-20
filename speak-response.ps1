# Hook script: speaks Claude last assistant message via Windows TTS
# v2: Sentence-by-sentence async playback, table columns kept
$ErrorActionPreference = "SilentlyContinue"
$jsonFile = "$env:USERPROFILE\.claude\last_msg.json"
if (-not (Test-Path $jsonFile)) { exit 0 }
try {
    $json = Get-Content $jsonFile -Raw -Encoding UTF8
    $data = $json | ConvertFrom-Json
    $text = $data.last_assistant_message
} catch { exit 0 }
if (-not $text.Trim()) { exit 0 }

# Strip Markdown
$text = $text -replace '\*\*(.+?)\*\*', '$1'
$text = $text -replace '\*(.+?)\*', '$1'
$text = $text -replace '__(.+?)__', '$1'
$text = $text -replace '_(.+?)_', '$1'
$text = $text -replace '`(.+?)`', '$1'
$text = $text -replace '\[(.+?)\]\(.+?\)', '$1'
$text = $text -replace '(?m)^#{1,6}\s+', ''
$text = $text -replace '(?m)^>\s+', ''
$text = $text -replace '(?m)^[-*_]{3,}\s*$', ''
$text = $text -replace '```[\s\S]*?```', ''
$text = $text -replace '~~~[\s\S]*?~~~', ''

# Table handling: pipe chars -> pauses (keeps all columns)
$text = $text -replace '(?m)^\|[-| :]+\|\s*$', ''
$text = $text -replace '\s*\|\s*', ', '

# Split into sentences
$sentences = [regex]::Split($text.Trim(), '(?<=[.!?' + [char]0x3002 + [char]0xFF01 + [char]0xFF1F + '\n])\s*') | Where-Object { $_.Trim() }
if (-not $sentences -or $sentences.Count -eq 0) { $sentences = @($text.Trim()) }

# Speak sentence by sentence
Add-Type -AssemblyName System.Speech
$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synth.Rate = 1
try { $synth.SelectVoice('Microsoft Xiaoxiao Online') } catch {}

foreach ($sentence in $sentences) {
    $trimmed = $sentence.Trim()
    if (-not $trimmed) { continue }
    # Add trailing comma if no sentence-ending punctuation -- forces TTS to pause
    if ($trimmed -notmatch '[.!?' + [char]0x3002 + [char]0xFF01 + [char]0xFF1F + ']\s*$') {
        $trimmed = $trimmed + ', '
    }
    try {
        $task = $synth.SpeakAsync($trimmed)
        while (-not $task.IsCompleted) { Start-Sleep -Milliseconds 100 }
    } catch { break }
}
$synth.Dispose()
