#!/usr/bin/env bash
# Take a Windows screenshot and copy it to /tmp/snap.png for Claude to Read.
set -uo pipefail

WIN_USER="${WIN_USER:-$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r' || echo "$USER")}"
PS_EXE="/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
WIN_TEMP="C:\\Users\\${WIN_USER}\\AppData\\Local\\Temp\\snap.png"
WSL_TEMP="/mnt/c/Users/${WIN_USER}/AppData/Local/Temp/snap.png"
OUTPUT="/tmp/snap.png"

if [ ! -f "$PS_EXE" ]; then
  echo "ERROR: PowerShell not found at $PS_EXE"
  echo "Try: bash ~/.claude/commands/snapshot/scripts/tmux-snap.sh"
  exit 1
fi

"$PS_EXE" -NoProfile -NonInteractive -Command "
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms
\$bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
\$bmp = New-Object System.Drawing.Bitmap(\$bounds.Width, \$bounds.Height)
\$g = [System.Drawing.Graphics]::FromImage(\$bmp)
\$g.CopyFromScreen(\$bounds.Location, [System.Drawing.Point]::Empty, \$bounds.Size)
\$bmp.Save('${WIN_TEMP}')
\$g.Dispose()
\$bmp.Dispose()
Write-Output 'captured'
" 2>/dev/null

if [ -f "$WSL_TEMP" ]; then
  cp "$WSL_TEMP" "$OUTPUT"
  echo "screenshot saved to $OUTPUT"
  echo "Read $OUTPUT to see the screen"
else
  echo "ERROR: screenshot file not found at $WSL_TEMP"
  echo "Falling back to tmux text capture..."
  bash "$(dirname "$0")/tmux-snap.sh"
fi
