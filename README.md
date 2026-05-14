# tts-reader

Command-line Text-to-Speech reader for Windows — no installation needed, powered by the built-in `System.Speech` engine.

## Features

- **Zero dependencies** — uses Windows built-in TTS engine
- **Adjustable speech rate** — from -10 (slowest) to 10 (fastest)
- **Keyboard controls** — real-time speed / pause / seek during playback (interactive mode)
- **Multiple voices** — Chinese (zh-CN, zh-TW) and English (en-US, en-GB)
- **Flexible input** — inline text, text files, or piped stdin

## Quick Start

```batch
# Clone this repo
git clone https://github.com/YOUR_USERNAME/tts-reader.git
cd tts-reader

# Add to PATH (optional — for global access)
setx PATH "%PATH%;%CD%"

# Start reading
tts "Hello, world"
```

## Usage

### Basic commands

```batch
tts "你好，世界"                        # Read text directly
tts -File document.txt                 # Read from a file
type report.txt | tts                  # Read from stdin / pipe
tts -Rate 5 "Faster speech"            # Adjust speed (-10 to 10)
tts -Voice "Microsoft Zira Desktop" "Hello"  # Switch voice
tts -ListVoices                        # Show all installed voices
tts -h                                 # Show help
```

### Keyboard controls (interactive mode)

Press these keys while TTS is playing:

| Key | Action |
|-----|--------|
| `+` / `=` | Speed up |
| `-` | Slow down |
| `Space` | Pause / Resume |
| `←` / `→` | Rewind / Fast-forward |
| `R` | Restart from beginning |
| `Q` / `Esc` | Quit |

### Parameters

| Parameter | Description | Default |
|-----------|------------|---------|
| `-Text` | Text to read (positional) | — |
| `-File` | Path to a text file | — |
| `-Rate` | Speech speed (-10 ~ 10) | `1` |
| `-Voice` | Voice name (use `-ListVoices` to see options) | System default |
| `-ListVoices` | Show installed TTS voices and exit | — |

## Requirements

- **Windows** (7 or later) — uses `System.Speech` which is built into the .NET Framework
- **PowerShell** (any version)

No extra downloads. No npm. No Python. Just PowerShell and Windows.

## Voices

Windows comes with these voices by default (varies by Windows version):

| Voice | Language |
|-------|----------|
| Microsoft Huihui | Chinese (zh-CN) |
| Microsoft Hanhan | Chinese (zh-TW) |
| Microsoft David | English (en-US) |
| Microsoft Zira | English (en-US) |
| Microsoft Hazel | English (en-GB) |

## License

MIT
