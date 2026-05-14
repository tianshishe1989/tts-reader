<#
.SYNOPSIS
  Text-to-Speech reader with adjustable speed and keyboard controls.
.DESCRIPTION
  Reads text from arguments, stdin, or a file using the Windows built-in TTS engine.
  Adjust speed on the fly and control playback with hotkeys.
.PARAMETER Text
  The text to read aloud. If omitted, reads from stdin or -File.
.PARAMETER File
  Path to a text file to read.
.PARAMETER Rate
  Speech speed from -10 (slowest) to 10 (fastest). Default: 1.
.PARAMETER Voice
  Voice name to use. Use -ListVoices to see available options.
.PARAMETER ListVoices
  List all installed TTS voices and exit.
.EXAMPLE
  tts "Hello, world"
  echo "Hello from stdin" | tts
  tts -File document.txt -Rate 2
  tts -ListVoices
#>

param(
    [string]$Text,
    [string]$File,
    [int]$Rate = 1,
    [string]$Voice,
    [switch]$ListVoices
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Speech

$synth = New-Object System.Speech.Synthesis.SpeechSynthesizer

# --- List voices & exit ---
if ($ListVoices) {
    Write-Host "`nAvailable voices:`n" -ForegroundColor Cyan
    foreach ($v in $synth.GetInstalledVoices()) {
        $vi = $v.VoiceInfo
        $cur = if ($vi.Name -eq $synth.Voice.Name) { " [current]" } else { "" }
        Write-Host "  $($vi.Name)  |  $($vi.Culture)  |  $($vi.Gender)$cur"
    }
    $synth.Dispose()
    exit 0
}

# --- Select voice ---
if ($Voice) {
    try { $synth.SelectVoice($Voice) }
    catch {
        Write-Host "Voice '$Voice' not found. Use -ListVoices to see options." -ForegroundColor Yellow
        $synth.Dispose()
        exit 1
    }
}
else {
    # Auto-prefer natural voices: Xiaoxiao > Xiaoyi > system default
    $preferred = @('Microsoft Xiaoxiao Online', 'Microsoft Xiaoyi Online')
    foreach ($v in $preferred) {
        try { $synth.SelectVoice($v); break } catch {}
    }
}

# --- Collect input ---
if ($File) {
    if (-not (Test-Path $File)) {
        Write-Host "File not found: $File" -ForegroundColor Red
        $synth.Dispose()
        exit 1
    }
    $Text = Get-Content $File -Raw -Encoding UTF8
}

if (-not $Text) {
    $stdin = $input | Out-String
    if ($stdin.Trim()) {
        $Text = $stdin
    }
    else {
        Write-Host "Usage: tts <text>  |  echo <text> | tts  |  tts -File <path>  |  tts -ListVoices" -ForegroundColor Cyan
        $synth.Dispose()
        exit 1
    }
}

# --- Setup ---
$rate  = if ($Rate -lt -10) { -10 } elseif ($Rate -gt 10) { 10 } else { $Rate }
$synth.Rate = $rate

# Detect if we have a real console for interactive controls
$hasConsole = $true
try { $null = [Console]::KeyAvailable } catch { $hasConsole = $false }

# Split into sentences for responsive control
$sentences = [regex]::Split($Text, '(?<=[.!?。！？\n])\s*') | Where-Object { $_.Trim() }
if (-not $sentences -or $sentences.Count -eq 0) {
    $sentences = @($Text)
}

# --- Simple mode (no console) ---
if (-not $hasConsole) {
    Write-Host "  Reading | Speed: $($synth.Rate) | Voice: $($synth.Voice.Name) (non-interactive)" -ForegroundColor Cyan
    $synth.Speak($Text)
    $synth.Dispose()
    Write-Host "  Done." -ForegroundColor Green
    exit 0
}

# --- Interactive mode ---
$state  = "playing"
$currentIdx = 0
$totalCount  = $sentences.Count

Write-Host "`n  Reading" -NoNewline -ForegroundColor Cyan
Write-Host " | Speed:" -NoNewline
Write-Host " $($synth.Rate)" -NoNewline -ForegroundColor Yellow
Write-Host " | Voice: $($synth.Voice.Name)" -NoNewline
Write-Host " | + - =speed  Space=pause  <- -> =seek  R=restart  Q=quit`n" -ForegroundColor DarkGray

function Show-Status {
    $icon = switch ($state) { "playing" { ">" } "paused" { "||" } "stopped" { "[]" } }
    $pct  = if ($totalCount -gt 0) { [int](($currentIdx / $totalCount) * 100) } else { 0 }
    Write-Host "`r  $icon [$pct%] " -NoNewline -ForegroundColor Cyan
    Write-Host "Speed:" -NoNewline
    Write-Host "$($synth.Rate)" -NoNewline -ForegroundColor Yellow
    Write-Host "  " -NoNewline
}

function Process-Key($key) {
    switch ($key.Key) {
        { $_ -eq "OemPlus" -or $_ -eq "Add" -or $_.KeyChar -eq '+' -or $_.KeyChar -eq '=' } {
            $script:rate = [Math]::Min(10, $script:rate + 1)
            $synth.Rate = $script:rate
            Show-Status
        }
        { $_ -eq "OemMinus" -or $_ -eq "Subtract" -or $_.KeyChar -eq '-' } {
            $script:rate = [Math]::Max(-10, $script:rate - 1)
            $synth.Rate = $script:rate
            Show-Status
        }
        "Spacebar" {
            if ($state -eq "playing") { $state = "paused" }
            elseif ($state -eq "paused") { $state = "playing" }
            Show-Status
        }
        "LeftArrow" {
            $script:currentIdx = [Math]::Max(0, $script:currentIdx - 2)
            if ($state -ne "stopped") { $synth.SpeakAsyncCancelAll() }
            Show-Status
        }
        "RightArrow" {
            $script:currentIdx = [Math]::Min($totalCount - 1, $script:currentIdx + 2)
            if ($state -ne "stopped") { $synth.SpeakAsyncCancelAll() }
            Show-Status
        }
        "R" {
            $script:currentIdx = 0
            if ($state -ne "stopped") { $synth.SpeakAsyncCancelAll() }
            $state = "playing"
            Show-Status
        }
        { $_ -eq "Q" -or $_ -eq "Escape" } {
            $state = "stopped"
            $synth.SpeakAsyncCancelAll()
        }
    }
}

# --- Main playback loop ---
Show-Status

while ($currentIdx -lt $totalCount -and $state -ne "stopped") {
    while ([Console]::KeyAvailable) {
        $k = [Console]::ReadKey($true)
        Process-Key $k
        if ($state -eq "stopped") { break }
    }

    if ($state -eq "stopped") { break }

    if ($state -eq "playing") {
        $sentence = $sentences[$currentIdx]
        $prompt = $synth.SpeakAsync($sentence)

        while (-not $prompt.IsCompleted) {
            Start-Sleep -Milliseconds 80

            while ([Console]::KeyAvailable) {
                $k = [Console]::ReadKey($true)
                Process-Key $k
                if ($state -eq "stopped" -or $state -eq "paused") { break }
            }

            if ($state -ne "playing") { break }
        }

        if ($state -eq "paused") {
            $synth.SpeakAsyncCancelAll()
            while ($state -eq "paused" -and $state -ne "stopped") {
                Start-Sleep -Milliseconds 100
                while ([Console]::KeyAvailable) {
                    $k = [Console]::ReadKey($true)
                    Process-Key $k
                    if ($state -eq "stopped" -or $state -eq "playing") { break }
                }
            }
            continue
        }

        if ($state -eq "playing") {
            $currentIdx++
            Show-Status
        }
    }
}

Write-Host "`nDone.`n" -ForegroundColor Green
$synth.Dispose()
