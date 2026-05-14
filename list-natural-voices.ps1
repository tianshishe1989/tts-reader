# Check available WinRT (natural) TTS voices - diagnostic version
$ErrorActionPreference = "Continue"

Write-Host "Checking WinRT voices..."

try {
    [Windows.Media.SpeechSynthesis.SpeechSynthesizer, Windows.Media.SpeechSynthesis, ContentType = WindowsRuntime] | Out-Null
    $synth = New-Object Windows.Media.SpeechSynthesis.SpeechSynthesizer

    $allVoices = $synth.AllVoices
    Write-Host "Voice count: $($allVoices.Count)"

    foreach ($v in $allVoices) {
        Write-Host "  $($v.DisplayName) | $($v.Language) | $($v.Gender)"
    }

    $synth.Dispose()
    Write-Host "Done."
} catch {
    Write-Host "Error: $($_.Exception.Message)"
}
