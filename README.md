# tts-reader

Command-line Text-to-Speech reader for Windows — powered by the built-in `System.Speech` engine. Read text aloud from the terminal with adjustable speed, voice selection, and keyboard controls.

## Features

- **Zero dependencies** — uses Windows built-in .NET TTS engine
- **Adjustable speed** — from -10 (slowest) to 10 (fastest)
- **Interactive controls** — real-time speed / pause / seek during playback
- **Natural voice support** — upgrade to Microsoft natural voices (Xiaoxiao, etc.)
- **Claude Code integration** — Stop hook for auto-reading assistant responses
- **Flexible input** — inline text, text files, piped stdin

## Quick Start

```batch
git clone https://github.com/tianshishe1989/tts-reader.git
cd tts-reader
setx PATH "%PATH%;%CD%"
tts "你好，世界"
```

## Usage

### CLI Commands

```batch
tts "你好，世界"                              # Direct text
tts -File document.txt                       # Read from file
type report.txt | tts                        # Piped stdin
tts -Rate 5 "Faster"                         # Speed (-10 ~ 10)
tts -Voice "Microsoft Zira Desktop" "Hello"  # Switch voice
tts -ListVoices                              # Show all voices
tts -h                                       # Help
```

### Keyboard Controls (interactive mode)

| Key | Action |
|-----|--------|
| `+` / `=` | Speed up |
| `-` | Slow down |
| `Space` | Pause / Resume |
| `←` / `→` | Rewind / Forward |
| `R` | Restart |
| `Q` / `Esc` | Quit |

## Natural Voices (Xiaoxiao)

Windows built-in voices are mechanical. For Microsoft's natural neural voices (the "Word Read Aloud" quality):

### Windows 11
Settings → Time & Language → Speech → Add voices → Install "Microsoft Xiaoxiao"

### Windows 10
Use [NaturalVoiceSAPIAdapter](https://github.com/gexgd0419/NaturalVoiceSAPIAdapter):
1. Download from Releases
2. Run `Installer.exe` as Administrator
3. Enable "Microsoft Edge Online Voices"
4. Install both 32-bit and 64-bit

Verify:
```batch
tts -ListVoices
# Should show: Microsoft Xiaoxiao Online, Microsoft Xiaoyi Online, etc.
```

Switch voice:
```batch
tts -Voice "Microsoft Xiaoxiao Online" "你好"
```

## Claude Code Auto-Read Hook

Make Claude Code automatically read its responses aloud via the Stop hook.

### Setup

**1. settings.json** (`.claude/settings.json`):
```json
{
  "hooks": {
    "Stop": [{
      "hooks": [{
        "type": "command",
        "command": "powershell -NoProfile -ExecutionPolicy Bypass -File \"C:\\path\\to\\stop-hook.ps1\"",
        "async": true,
        "timeout": 120
      }]
    }]
  }
}
```

**2. Files in this repo:**
- `stop-hook.ps1` — receives stdin JSON from hook, saves to temp file, launches TTS
- `speak-response.ps1` — reads saved JSON, extracts `last_assistant_message`, speaks it

**3.** Restart Claude Code. Every response will be spoken automatically.

## Files

| File | Purpose |
|------|---------|
| `tts.ps1` | Main CLI TTS reader |
| `tts.bat` | CMD wrapper for easy invocation |
| `stop-hook.ps1` | Claude Code Stop hook entry point |
| `speak-response.ps1` | Hook TTS speaker (reads from JSON) |
| `list-natural-voices.ps1` | List WinRT natural voices |

## Requirements

- **Windows** 7+ with .NET Framework
- **PowerShell** (any version)
- **Natural voices**: Windows 11 native, or NaturalVoiceSAPIAdapter on Windows 10

## License

MIT
