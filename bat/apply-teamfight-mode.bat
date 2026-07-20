@echo off
:: league-of-legends-teamfight-mode - v2.0.1
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
echo   league-of-legends-teamfight-mode  v2.0.1  @thiagocajadev
echo   --------------------------------------------------------
echo   Config: %LOL_CONFIG_DIR%
echo.
echo   [1] Apply Teamfight Mode
echo       zoom locked, range, camera and target on Space
echo       fewer misclicks, better fight reads
echo.
echo   [2] Restore the original files (.bak)
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

# why: a Riot grava o mesmo arquivo como "Input.ini" e "input.ini" conforme a versao,
# entao o nome do disco e o nome dentro do JSON sao declarados separados
$hotkeyPresets = @{
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
  # why: as tres chaves so funcionam juntas. O [space] repetido amarra alcance,
  # camera e alvo no mesmo gesto, e o AsToggle=0 faz valer enquanto segura.
  # Em 1 viraria liga/desliga e a combinacao quebra.
  range = @{
    Label    = 'Attack range, lock camera and target champions'
    Settings = @(
      @{
        IniFile       = 'input.ini'
        PersistedFile = 'Input.ini'
        Section       = 'GameEvents'
        Key           = 'evtShowCharacterMenu'
        Value         = '[c],[space]'
      },
      @{
        IniFile       = 'input.ini'
        PersistedFile = 'Input.ini'
        Section       = 'GameEvents'
        Key           = 'evtChampionOnly'
        Value         = '[n],[space]'
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

function Find-LeagueDirectory {
  $fromProcess = Find-DirectoryFromProcess

  if ($null -ne $fromProcess) {
    return $fromProcess
  }

  $fromMetadata = Find-DirectoryFromMetadata
  return $fromMetadata
}

function Find-DirectoryFromProcess {
  # why: o executavel do jogo fica em <instalacao>\Game, o do cliente na raiz
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

  # why: o anticheat bloqueia .Path do Get-Process, e o CIM costuma passar
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

  # why: rodar duas vezes nao pode sobrescrever o backup com o arquivo ja modificado
  if ($hasBackup -or -not (Test-Path -LiteralPath $Path)) {
    return
  }

  Copy-Item -LiteralPath $Path -Destination $backupPath
  Write-Host "  backup created: $(Split-Path $backupPath -Leaf)"
}

function Set-IniSetting {
  param([string]$Path, [string]$Section, [string]$Key, [string]$Value)

  # why: arquivo ausente significa que o cliente nunca gravou config. Criar um do zero
  # produziria arquivo sem .bak, que a opcao 2 nao saberia desfazer
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

  # why: a Riot nem sempre guarda a chave na secao que a gente espera. Achar onde ela
  # ja esta evita criar uma segunda copia numa secao errada, que o cliente ignoraria
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

  # why: as chaves ficam espalhadas por secoes diferentes, entao procurar no arquivo
  # inteiro evita criar uma segunda copia na secao declarada, que o cliente ignoraria
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

function Invoke-TeamfightMode {
  # why: passo unico e deliberado, garante que todo .bak seja a copia pre-alteracao,
  # sem estado intermediario para o usuario decifrar ao voltar atras
  $orderedPresets = @($hotkeyPresets.zoom, $hotkeyPresets.range)
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
    $iniPath = Join-Path $configDirectory $setting.IniFile
    Backup-ConfigFile -Path $iniPath

    Set-IniSetting -Path $iniPath -Section $setting.Section -Key $setting.Key -Value $setting.Value
    Write-Host "  $($setting.IniFile): [$($setting.Section)] $($setting.Key)=$($setting.Value)"

    Set-PersistedSetting -Path $PersistedPath -FileName $setting.PersistedFile `
      -Section $setting.Section -Key $setting.Key -Value $setting.Value
    Write-Host "  PersistedSettings.json: $($setting.PersistedFile) / $($setting.Key) = $($setting.Value)"
  }
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

Invoke-TeamfightMode
exit 0
