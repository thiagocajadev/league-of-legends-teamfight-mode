@echo off
:: league-of-legends-teamfight-mode - v2.2.1
:: @thiagocajadev
:: github.com/thiagocajadev/league-of-legends-teamfight-mode
setlocal EnableExtensions EnableDelayedExpansion
title league-of-legends-teamfight-mode

set "SELF=%~f0"
set "LOL_DIR="
set "HOTKEY_ACTION=detect"

echo Looking for the League of Legends installation...

for /f "usebackq delims=" %%p in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$raw = Get-Content -LiteralPath $env:SELF -Raw; $engine = ($raw -split '#PS_ENGINE_START#')[-1]; Invoke-Expression -Command $engine"`) do set "LOL_DIR=%%p"

if not defined LOL_DIR set "LOL_DIR=C:\Riot Games\League of Legends"

if not exist "%LOL_DIR%\Config" (
  echo.
  echo Could not find the League of Legends installation.
  echo Checked the running process, the Riot metadata and:
  echo   %LOL_DIR%
  echo.
  set /p "LOL_DIR=Enter the installation folder: "
)

set "LOL_CONFIG_DIR=%LOL_DIR%\Config"

if not exist "%LOL_CONFIG_DIR%" (
  echo.
  echo ERROR: config folder does not exist: %LOL_CONFIG_DIR%
  echo Nothing was changed.
  echo.
  pause
  exit /b 1
)

:menu
cls
echo.
echo   league-of-legends-teamfight-mode  v2.2.1  @thiagocajadev
echo   --------------------------------------------------------
echo   Config: %LOL_CONFIG_DIR%
echo.
echo   [1] Apply Teamfight Mode
echo       zoom locked. Range, camera and target on Space
echo       fewer misclicks, better fight reads
echo.
echo   [2] Restore the original files (.bak)
echo   [3] Advanced: swap Space for another key
echo   [0] Exit
echo.
set "MENU_CHOICE="
set /p "MENU_CHOICE=Choose an option: "

if "%MENU_CHOICE%"=="1" (
  set "HOTKEY_ACTION=apply"
  goto engine
)
if "%MENU_CHOICE%"=="2" (
  set "HOTKEY_ACTION=restore"
  goto engine
)
if "%MENU_CHOICE%"=="3" (
  set "HOTKEY_ACTION=advanced"
  goto engine
)
if "%MENU_CHOICE%"=="0" exit /b 0

echo Invalid option.
timeout /t 2 >nul
goto menu

:engine
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$raw = Get-Content -LiteralPath $env:SELF -Raw; $engine = ($raw -split '#PS_ENGINE_START#')[-1]; Invoke-Expression -Command $engine"

set "ENGINE_EXIT=%ERRORLEVEL%"

echo.
pause
if not "%ENGINE_EXIT%"=="0" exit /b %ENGINE_EXIT%
goto menu

#PS_ENGINE_START#

$ErrorActionPreference = 'Stop'

$configDirectory = $env:LOL_CONFIG_DIR
$action = $env:HOTKEY_ACTION

# why: for a non-printing key RawUI.ReadKey returns a Windows virtual key code, not a
# character. Named here because a bare number inside an if says nothing
$escapeKeyCode = 27
$enterKeyCode = 13
$mouseMenuKeyCode = 77
$spaceKeyCode = 32
$tabKeyCode = 9
$firstFunctionKeyCode = 112
$lastFunctionKeyCode = 123

# why: the questions have three exits, not two. "No" moves on to another useful path,
# and only Esc gives up, so a boolean would not cover it
$answerYes = 'yes'
$answerNo = 'no'
$answerCancel = 'cancel'
$answerEchoes = @{ yes = 'Y'; no = 'N'; cancel = 'canceled' }

# why: the game reserves left, right and scroll for moving, attacking and zooming. The
# range starts at 4 and goes to 9 to cover mice with more than two extra buttons
$extraMouseButtonPattern = '^[4-9]$'

# why: Riot writes the same file as "Input.ini" and "input.ini" depending on the
# version, so the name on disk and the name inside the JSON are declared separately
function Get-HotkeyPresets {
  param([string]$TriggerKey = '[space]', [string]$TriggerLabel = 'Space')

  $presets = @{
    zoom = @{
      Label    = 'Zoom via mouse scroll disabled'
      Settings = @(
        @{
          IniFile       = 'input.ini'
          PersistedFile = 'Input.ini'
          Section       = 'MouseSettings'
          Key           = 'RollerButtonSpeed'
          Value         = '0'
        }
      )
    }
    # why: the combo assumes an unlocked camera. With CameraMode=1 it is already
    # locked and the combo key has nothing to snap, so the whole gesture loses effect.
    camera = @{
      Label    = "Unlocked camera with lock on $TriggerLabel"
      Settings = @(
        @{
          IniFile       = 'input.ini'
          PersistedFile = 'Input.ini'
          Section       = 'GameEvents'
          Key           = 'evtCameraSnap'
          Value         = $TriggerKey
        },
        @{
          PersistedFile = 'Game.cfg'
          Section       = 'General'
          Key           = 'CameraMode'
          Value         = '0'
        }
      )
    }
    # why: the three settings only work together. The repeated key ties range, camera
    # and target to the same gesture, and AsToggle=0 keeps it active while held.
    # At 1 it would become on/off and the combination breaks.
    range = @{
      Label    = 'Attack range, lock camera and target champions'
      Settings = @(
        @{
          IniFile       = 'input.ini'
          PersistedFile = 'Input.ini'
          Section       = 'GameEvents'
          Key           = 'evtShowCharacterMenu'
          Value         = "[c],$TriggerKey"
        },
        @{
          IniFile       = 'input.ini'
          PersistedFile = 'Input.ini'
          Section       = 'GameEvents'
          Key           = 'evtChampionOnly'
          Value         = "[n],$TriggerKey"
        },
        @{
          IniFile       = 'input.ini'
          PersistedFile = 'Input.ini'
          Section       = 'GameEvents'
          Key           = 'TargetChampionsOnlyAsToggle'
          Value         = '0'
        }
      )
    }
  }

  return $presets
}

function Find-LeagueDirectory {
  $fromProcess = Find-DirectoryFromProcess

  if ($null -ne $fromProcess) {
    return $fromProcess
  }

  $fromMetadata = Find-DirectoryFromMetadata
  return $fromMetadata
}

function Find-DirectoryFromProcess {
  # why: the game executable sits in <install>\Game, the client one in the root
  $executableNames = @('League of Legends.exe', 'LeagueClient.exe')

  foreach ($executableName in $executableNames) {
    $executablePath = Get-ProcessExecutablePath -ExecutableName $executableName

    if ([string]::IsNullOrWhiteSpace($executablePath)) {
      continue
    }

    $candidate = Split-Path $executablePath -Parent

    if ((Split-Path $candidate -Leaf) -ieq 'Game') {
      $candidate = Split-Path $candidate -Parent
    }

    if (Test-Path -LiteralPath (Join-Path $candidate 'Config')) {
      return $candidate
    }
  }

  $notFound = $null
  return $notFound
}

function Get-ProcessExecutablePath {
  param([string]$ExecutableName)

  # why: the anticheat blocks .Path from Get-Process, and CIM usually gets through
  try {
    $filter = "name='$ExecutableName'"
    $processEntry = Get-CimInstance Win32_Process -Filter $filter -ErrorAction SilentlyContinue |
      Select-Object -First 1

    if ($null -ne $processEntry) {
      return $processEntry.ExecutablePath
    }
  } catch {
    $cimFailed = $null
  }

  $noPath = $null
  return $noPath
}

function Find-DirectoryFromMetadata {
  $metadataPath = 'C:\ProgramData\Riot Games\Metadata\league_of_legends.live\league_of_legends.live.product_settings.yaml'

  if (-not (Test-Path -LiteralPath $metadataPath)) {
    $noMetadata = $null
    return $noMetadata
  }

  $match = Select-String -Path $metadataPath -Pattern 'product_install_full_path:\s*"?([^"\r\n]+)"?' |
    Select-Object -First 1

  if ($null -eq $match) {
    $noMatch = $null
    return $noMatch
  }

  $candidate = $match.Matches[0].Groups[1].Value.Trim()

  if (Test-Path -LiteralPath (Join-Path $candidate 'Config')) {
    return $candidate
  }

  $noConfig = $null
  return $noConfig
}

function Backup-ConfigFile {
  param([string]$Path)

  $backupPath = "$Path.bak"
  $hasBackup = Test-Path -LiteralPath $backupPath

  # why: running twice cannot overwrite the backup with the already modified file
  if ($hasBackup -or -not (Test-Path -LiteralPath $Path)) {
    return
  }

  Copy-Item -LiteralPath $Path -Destination $backupPath
  Write-Host "  backup created: $(Split-Path $backupPath -Leaf)"
}

function Set-IniSetting {
  param([string]$Path, [string]$Section, [string]$Key, [string]$Value)

  # why: a missing file means the client never wrote config. Creating one from scratch
  # would produce a file with no .bak, which option 2 would not know how to undo
  if (-not (Test-Path -LiteralPath $Path)) {
    Write-Host "  $(Split-Path $Path -Leaf) missing, skipped"
    return
  }

  $lines = @(Get-Content -LiteralPath $Path)

  $sectionIndex = Find-SectionIndex -Lines $lines -Section $Section
  $sectionEnd = $lines.Count

  if ($sectionIndex -ge 0) {
    $sectionEnd = Find-SectionEnd -Lines $lines -StartIndex $sectionIndex
  }

  $keyIndex = -1
  if ($sectionIndex -ge 0) {
    $keyIndex = Find-KeyIndex -Lines $lines -Key $Key -From ($sectionIndex + 1) -To $sectionEnd
  }

  # why: Riot does not always keep the setting in the section we expect. Finding where
  # it already sits avoids a second copy in a wrong section, which the client ignores
  if ($keyIndex -lt 0) {
    $keyIndex = Find-KeyIndex -Lines $lines -Key $Key -From 0 -To $lines.Count
  }

  if ($keyIndex -ge 0) {
    $lines[$keyIndex] = "$Key=$Value"
    Set-Content -LiteralPath $Path -Value $lines
    return
  }

  if ($sectionIndex -lt 0) {
    $appended = @($lines) + '' + "[$Section]" + "$Key=$Value"
    Set-Content -LiteralPath $Path -Value $appended
    return
  }

  $head = @($lines[0..($sectionEnd - 1)])
  $tail = @()
  if ($sectionEnd -lt $lines.Count) {
    $tail = @($lines[$sectionEnd..($lines.Count - 1)])
  }

  $merged = $head + "$Key=$Value" + $tail
  Set-Content -LiteralPath $Path -Value $merged
}

function Find-SectionIndex {
  param([string[]]$Lines, [string]$Section)

  for ($index = 0; $index -lt $Lines.Count; $index++) {
    if ($Lines[$index].Trim() -ieq "[$Section]") {
      return $index
    }
  }

  return -1
}

function Find-SectionEnd {
  param([string[]]$Lines, [int]$StartIndex)

  for ($index = $StartIndex + 1; $index -lt $Lines.Count; $index++) {
    if ($Lines[$index].Trim().StartsWith('[')) {
      return $index
    }
  }

  return $Lines.Count
}

function Find-KeyIndex {
  param([string[]]$Lines, [string]$Key, [int]$From, [int]$To)

  $pattern = "^\s*$([regex]::Escape($Key))\s*="

  for ($index = $From; $index -lt $To; $index++) {
    if ($Lines[$index] -imatch $pattern) {
      return $index
    }
  }

  return -1
}

function Set-PersistedSetting {
  param([string]$Path, [string]$FileName, [string]$Section, [string]$Key, [string]$Value)

  if (-not (Test-Path -LiteralPath $Path)) {
    Write-Host "  PersistedSettings.json missing, skipped"
    return
  }

  $root = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json

  # why: the settings are spread across different sections, so searching the whole file
  # avoids a second copy in the declared section, which the client would ignore
  $existing = Find-PersistedSetting -Root $root -Key $Key

  if ($null -ne $existing) {
    Set-NamedProperty -Target $existing -Name 'value' -Value $Value
    $found = $root | ConvertTo-Json -Depth 100
    Set-Content -LiteralPath $Path -Value $found -Encoding UTF8
    return
  }

  $fileEntry = Get-OrAddNamedChild -Owner $root -ListProperty 'files' -Name $FileName `
    -Template ([pscustomobject]@{ name = $FileName; sections = @() })

  $sectionEntry = Get-OrAddNamedChild -Owner $fileEntry -ListProperty 'sections' -Name $Section `
    -Template ([pscustomobject]@{ name = $Section; settings = @() })

  $settingEntry = Get-OrAddNamedChild -Owner $sectionEntry -ListProperty 'settings' -Name $Key `
    -Template ([pscustomobject]@{ name = $Key; value = $Value })

  Set-NamedProperty -Target $settingEntry -Name 'value' -Value $Value

  $serialized = $root | ConvertTo-Json -Depth 100
  Set-Content -LiteralPath $Path -Value $serialized -Encoding UTF8
}

function Find-PersistedSetting {
  param($Root, [string]$Key)

  foreach ($fileEntry in @($Root.files)) {
    foreach ($sectionEntry in @($fileEntry.sections)) {
      $match = @($sectionEntry.settings) | Where-Object { $_.name -ieq $Key } | Select-Object -First 1

      if ($null -ne $match) {
        return $match
      }
    }
  }

  $notFound = $null
  return $notFound
}

function Get-OrAddNamedChild {
  param($Owner, [string]$ListProperty, [string]$Name, $Template)

  if (-not $Owner.PSObject.Properties.Match($ListProperty).Count) {
    $Owner | Add-Member -NotePropertyName $ListProperty -NotePropertyValue @()
  }

  $children = @()
  if ($null -ne $Owner.$ListProperty) {
    $children = @($Owner.$ListProperty)
  }

  $existing = $children | Where-Object { $_.name -ieq $Name } | Select-Object -First 1
  if ($null -ne $existing) {
    return $existing
  }

  $Owner.$ListProperty = @($children + $Template)
  return $Template
}

function Set-NamedProperty {
  param($Target, [string]$Name, [string]$Value)

  if (-not $Target.PSObject.Properties.Match($Name).Count) {
    $Target | Add-Member -NotePropertyName $Name -NotePropertyValue $Value
    return
  }

  $Target.$Name = $Value
}

function Invoke-AdvancedMode {
  Write-Host "  Advanced Mode"
  Write-Host "  ------------------------------------------------"
  Write-Host "  Teamfight Mode uses Space as the combo key."
  Write-Host ""
  Write-Host "  Off the list: C and N, already in the combo, M opens the mouse and Esc cancels."
  Write-Host "  Use a letter, a number, F1 to F12, space, tab or an extra mouse button."
  Write-Host ""

  $wantsSwap = Read-Answer -Question '  Swap Space for another key? (Y/n): '

  if ($wantsSwap -eq $answerCancel) {
    Show-CancelNotice
    return
  }

  if ($wantsSwap -eq $answerNo) {
    Write-Host ""
    Invoke-TeamfightMode
    return
  }

  $trigger = Read-TriggerUntilConfirmed

  if ($null -eq $trigger) {
    Show-CancelNotice
    return
  }

  Write-Host ""
  Invoke-TeamfightMode -TriggerKey $trigger.Token -TriggerLabel $trigger.Label
}

function Show-CancelNotice {
  Write-Host ""
  Write-Host "Canceled. Nothing was changed."
}

function Read-TriggerUntilConfirmed {
  # why: the choice repeats until confirmed, and nothing is written before that. A wrong
  # key never becomes a file change, which option 2 would have to undo afterwards
  while ($true) {
    $candidate = Read-TriggerCandidate

    if ($null -eq $candidate) {
      $canceled = $null
      return $canceled
    }

    $answer = Confirm-Trigger -Candidate $candidate

    if ($answer -eq $answerCancel) {
      $abandoned = $null
      return $abandoned
    }

    if ($answer -eq $answerYes) {
      return $candidate
    }
  }
}

function Read-TriggerCandidate {
  # why: a key off the list only repeats the question, and Esc is the single way out.
  # Without this a wrong key would end the wizard, mixing "mistyped" with "gave up"
  while ($true) {
    $pressed = Read-PressedTriggerKey

    if ($pressed.VirtualKeyCode -eq $escapeKeyCode) {
      $canceled = $null
      return $canceled
    }

    $token = Read-TokenFromKey -PressedKey $pressed
    $candidate = New-TriggerCandidate -Token $token

    if ($null -ne $candidate) {
      return $candidate
    }
  }
}

function Read-PressedTriggerKey {
  Write-Host ""
  Write-Host "  Press the key you want."
  Write-Host "  [M] opens the mouse buttons, [Esc] cancels."
  Write-Host ""
  Write-Host -NoNewline "  Key: "

  $pressed = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
  return $pressed
}

function Read-TokenFromKey {
  param($PressedKey)

  if ($PressedKey.VirtualKeyCode -eq $mouseMenuKeyCode) {
    Write-Host "M"
    $mouseToken = Read-MouseButton
    return $mouseToken
  }

  $keyboardToken = ConvertTo-HotkeyToken -PressedKey $PressedKey
  return $keyboardToken
}

function New-TriggerCandidate {
  param([string]$Token)

  if ([string]::IsNullOrWhiteSpace($Token)) {
    Write-Host ""
    Write-Host "  Key not supported. Use a letter, a number, F1 to F12, space, tab or mouse."
    $unsupported = $null
    return $unsupported
  }

  if (Test-ReservedToken -Token $Token) {
    Write-Host ""
    Write-Host "  $Token already belongs to the combo. The pair would collapse into one key."
    $reserved = $null
    return $reserved
  }

  # why: ReadKey runs with NoEcho, so without this Write-Host the prompt line stays
  # open and the next question comes out glued to it
  $label = ConvertTo-KeyLabel -Token $Token
  Write-Host $label

  $candidate = [pscustomobject]@{ Token = $Token; Label = $label }
  return $candidate
}

# why: narrow allowlist on purpose. LoL token spelling is only known for sure for
# letters, digits, F1-F12, space and tab. Accepting anything else would write a bind
# the game silently ignores, and the user would blame the script
function ConvertTo-HotkeyToken {
  param($PressedKey)

  $virtualKey = $PressedKey.VirtualKeyCode

  if ($virtualKey -ge $firstFunctionKeyCode -and $virtualKey -le $lastFunctionKeyCode) {
    $functionKey = "[f$($virtualKey - $firstFunctionKeyCode + 1)]"
    return $functionKey
  }

  if ($virtualKey -eq $spaceKeyCode) {
    $spaceKey = '[space]'
    return $spaceKey
  }

  if ($virtualKey -eq $tabKeyCode) {
    $tabKey = '[tab]'
    return $tabKey
  }

  $character = "$($PressedKey.Character)"

  if ($character -match '^[a-zA-Z0-9]$') {
    $printableKey = "[$($character.ToLower())]"
    return $printableKey
  }

  $unsupported = $null
  return $unsupported
}

function Read-MouseButton {
  Write-Host ""
  Write-Host "  Left, right and scroll stay out: the game already uses all three."
  Write-Host "  Pick the extra button, between 4 and 9. Most mice have 4 and 5."
  Write-Host ""
  Write-Host -NoNewline "  Button: "

  $pressed = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
  $chosen = "$($pressed.Character)"
  Write-Host $chosen

  if ($chosen -notmatch $extraMouseButtonPattern) {
    $invalid = $null
    return $invalid
  }

  # why: LoL writes mouse buttons with a capital B, "[Button 4]", unlike keyboard keys,
  # which stay lowercase. This is not a spelling slip, it is the file format
  $buttonToken = "[Button $chosen]"
  return $buttonToken
}

function Test-ReservedToken {
  param([string]$Token)

  # why: [c] and [n] are already the combo modifiers. Picking one would produce
  # evtShowCharacterMenu=[c],[c], and a pair of equal keys becomes a single key
  $reservedTokens = @('[c]', '[n]')
  $isReserved = $reservedTokens -contains $Token
  return $isReserved
}

function ConvertTo-KeyLabel {
  param([string]$Token)

  $bareName = $Token.Trim('[', ']')

  if ($bareName -eq 'space') {
    $spaceLabel = 'Space'
    return $spaceLabel
  }

  if ($bareName -like 'Button *') {
    $buttonLabel = "Mouse button $($bareName.Split(' ')[-1])"
    return $buttonLabel
  }

  $upperLabel = $bareName.ToUpper()
  return $upperLabel
}

function Confirm-Trigger {
  param($Candidate)

  # why: the conflict goes inside the confirmation itself. Asking "use it anyway" and
  # then "confirm" would be two questions for the same decision
  Show-KeyConflict -Token $Candidate.Token

  Write-Host ""
  Write-Host "  [Y] map on $($Candidate.Label)   [N] pick another key   [Esc] cancel"

  $answer = Read-Answer -Question '  Confirm? (Y/n): '
  return $answer
}

function Show-KeyConflict {
  param([string]$Token)

  $conflicts = @(Find-KeyConflict -Token $Token)

  if ($conflicts.Count -eq 0) {
    return
  }

  Write-Host ""
  Write-Host "  Heads up: this key is already in use in input.ini:"

  foreach ($conflict in $conflicts) {
    Write-Host "    $($conflict.Trim())"
  }
}

function Find-KeyConflict {
  param([string]$Token)

  $iniPath = Join-Path $configDirectory 'input.ini'

  if (-not (Test-Path -LiteralPath $iniPath)) {
    $noFile = @()
    return $noFile
  }

  # why: the three combo keys receive the new key on purpose, so showing up in them
  # is no conflict. Without this exclusion the warning would fire against the script
  $comboKeys = @('evtCameraSnap', 'evtShowCharacterMenu', 'evtChampionOnly')
  $lines = @(Get-Content -LiteralPath $iniPath)
  $conflicts = @($lines | Where-Object { Test-TokenInLine -Line $_ -Token $Token -ComboKeys $comboKeys })

  return $conflicts
}

function Test-TokenInLine {
  param([string]$Line, [string]$Token, [string[]]$ComboKeys)

  $separatorIndex = $Line.IndexOf('=')

  if ($separatorIndex -lt 1) {
    $isNotAssignment = $false
    return $isNotAssignment
  }

  $keyName = $Line.Substring(0, $separatorIndex).Trim()

  if ($ComboKeys -contains $keyName) {
    $isOwnedByCombo = $false
    return $isOwnedByCombo
  }

  # why: LoL separates keys with a comma inside the same setting, so matching the whole
  # line would give a false positive: [c] would match inside [c],[space]
  $boundTokens = @($Line.Substring($separatorIndex + 1).Split(',') | ForEach-Object { $_.Trim() })
  $hasToken = $boundTokens -contains $Token
  return $hasToken
}

# why: a single key press on every question, and Esc cancels on any of them. With
# Read-Host each question would demand Enter and none would see Esc, so the way to give
# up would change from screen to screen
function Read-Answer {
  param([string]$Question)

  Write-Host -NoNewline $Question

  $answer = $null
  while ($null -eq $answer) {
    $pressed = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    $answer = ConvertTo-Answer -PressedKey $pressed
  }

  Write-Host $answerEchoes[$answer]
  return $answer
}

function ConvertTo-Answer {
  param($PressedKey)

  if ($PressedKey.VirtualKeyCode -eq $escapeKeyCode) {
    return $answerCancel
  }

  # why: Enter means yes, the default announced in the (Y/n) of every question
  if ($PressedKey.VirtualKeyCode -eq $enterKeyCode) {
    return $answerYes
  }

  $character = "$($PressedKey.Character)"

  if ($character -imatch '^y$') {
    return $answerYes
  }

  if ($character -imatch '^n$') {
    return $answerNo
  }

  # why: a key outside the options decides nothing, so the question stays open
  $ignored = $null
  return $ignored
}

function Invoke-TeamfightMode {
  param([string]$TriggerKey = '[space]', [string]$TriggerLabel = 'Space')

  # why: single step on purpose, so every .bak is the copy from before any change,
  # with no intermediate state for the user to decode when rolling back
  $presets = Get-HotkeyPresets -TriggerKey $TriggerKey -TriggerLabel $TriggerLabel
  $orderedPresets = @($presets.zoom, $presets.camera, $presets.range)
  $persistedPath = Join-Path $configDirectory 'PersistedSettings.json'

  Backup-ConfigFile -Path $persistedPath

  foreach ($preset in $orderedPresets) {
    Write-Host "  $($preset.Label)"
    Invoke-Preset -Preset $preset -PersistedPath $persistedPath
  }

  Write-Host ""
  Write-Host "OK - Teamfight Mode applied"
  Write-Host "Close practice tool and open it again to reload the settings."
}

function Invoke-Preset {
  param([hashtable]$Preset, [string]$PersistedPath)

  foreach ($setting in $Preset.Settings) {
    Write-IniTarget -Setting $setting
    Write-PersistedTarget -Setting $setting -PersistedPath $PersistedPath
  }
}

# why: not every setting lives in both files. A target the preset does not declare is
# skipped, otherwise the setting would land in the wrong file and the client ignores it
function Write-IniTarget {
  param([hashtable]$Setting)

  if ([string]::IsNullOrWhiteSpace($Setting.IniFile)) {
    return
  }

  $iniPath = Join-Path $configDirectory $Setting.IniFile
  Backup-ConfigFile -Path $iniPath

  Set-IniSetting -Path $iniPath -Section $Setting.Section -Key $Setting.Key -Value $Setting.Value
  Write-Host "  $($Setting.IniFile): [$($Setting.Section)] $($Setting.Key)=$($Setting.Value)"
}

function Write-PersistedTarget {
  param([hashtable]$Setting, [string]$PersistedPath)

  if ([string]::IsNullOrWhiteSpace($Setting.PersistedFile)) {
    return
  }

  Set-PersistedSetting -Path $PersistedPath -FileName $Setting.PersistedFile `
    -Section $Setting.Section -Key $Setting.Key -Value $Setting.Value
  Write-Host "  PersistedSettings.json: $($Setting.PersistedFile) / $($Setting.Key) = $($Setting.Value)"
}

function Invoke-Restore {
  $backups = @(Get-ChildItem -LiteralPath $configDirectory -Filter '*.bak' -File -ErrorAction SilentlyContinue)

  if ($backups.Count -eq 0) {
    Write-Host "No .bak backup found in $configDirectory"
    exit 3
  }

  foreach ($backup in $backups) {
    $originalPath = $backup.FullName -replace '\.bak$', ''
    Copy-Item -LiteralPath $backup.FullName -Destination $originalPath -Force
    Write-Host "  restored: $(Split-Path $originalPath -Leaf)"
  }

  Write-Host ""
  Write-Host "OK - original files restored"
  Write-Host "Close practice tool and open it again to reload the settings."
}

if ($action -eq 'detect') {
  $detected = Find-LeagueDirectory

  if ($null -ne $detected) {
    Write-Output $detected
  }

  exit 0
}

if ($action -eq 'restore') {
  Invoke-Restore
  exit 0
}

if ($action -eq 'advanced') {
  Invoke-AdvancedMode
  exit 0
}

Invoke-TeamfightMode
exit 0
