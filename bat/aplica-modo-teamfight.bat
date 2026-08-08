@echo off
:: league-of-legends-teamfight-mode - v2.2.1
:: @thiagocajadev
:: github.com/thiagocajadev/league-of-legends-teamfight-mode
setlocal EnableExtensions EnableDelayedExpansion
title league-of-legends-teamfight-mode

set "SELF=%~f0"
set "LOL_DIR="
set "HOTKEY_ACTION=detect"

echo Procurando a instalacao do League of Legends...

for /f "usebackq delims=" %%p in (`powershell -NoProfile -ExecutionPolicy Bypass -Command "$raw = Get-Content -LiteralPath $env:SELF -Raw; $engine = ($raw -split '#PS_ENGINE_START#')[-1]; Invoke-Expression -Command $engine"`) do set "LOL_DIR=%%p"

if not defined LOL_DIR set "LOL_DIR=C:\Riot Games\League of Legends"

if not exist "%LOL_DIR%\Config" (
  echo.
  echo Nao encontrei a instalacao do League of Legends.
  echo Procurei no processo em execucao, no registro da Riot e em:
  echo   %LOL_DIR%
  echo.
  set /p "LOL_DIR=Informe a pasta de instalacao: "
)

set "LOL_CONFIG_DIR=%LOL_DIR%\Config"

if not exist "%LOL_CONFIG_DIR%" (
  echo.
  echo ERRO: pasta de config inexistente: %LOL_CONFIG_DIR%
  echo Nada foi alterado.
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
echo   [1] Aplicar o Modo Teamfight
echo       zoom travado. Alcance, camera e alvo no Espaco
echo       menos misclick, mais leitura de luta
echo.
echo   [2] Restaurar os arquivos originais (.bak)
echo   [3] Avancado: trocar o Espaco por outra tecla
echo   [0] Sair
echo.
set "MENU_CHOICE="
set /p "MENU_CHOICE=Escolha uma opcao: "

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

echo Opcao invalida.
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

# why: para tecla sem impressao o RawUI.ReadKey entrega codigo de tecla virtual do
# Windows, e nao caractere. Nomeados aqui porque o numero solto no if nao diz nada
$escapeKeyCode = 27
$enterKeyCode = 13
$mouseMenuKeyCode = 77
$spaceKeyCode = 32
$tabKeyCode = 9
$firstFunctionKeyCode = 112
$lastFunctionKeyCode = 123

# why: as perguntas tem tres saidas, nao duas. O "nao" segue para outro caminho util,
# e so o Esc desiste, entao um booleano nao daria conta
$answerYes = 'yes'
$answerNo = 'no'
$answerCancel = 'cancel'
$answerEchoes = @{ yes = 'S'; no = 'N'; cancel = 'cancelado' }

# why: o jogo reserva esquerdo, direito e scroll para mover, atacar e dar zoom. A faixa
# comeca no 4 e vai ate o 9 para atender mouse com mais de dois botoes extras
$extraMouseButtonPattern = '^[4-9]$'

# why: a Riot grava o mesmo arquivo como "Input.ini" e "input.ini" conforme a versao,
# entao o nome do disco e o nome dentro do JSON sao declarados separados
function Get-HotkeyPresets {
  param([string]$TriggerKey = '[space]', [string]$TriggerLabel = 'Espaco')

  $presets = @{
    zoom = @{
      Label    = 'Zoom via scroll desabilitado'
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
    # why: o combo pressupoe camera solta. Com CameraMode=1 ela ja fica travada
    # e a tecla do combo nao tem o que fixar, entao o gesto inteiro perde efeito.
    camera = @{
      Label    = "Camera solta com trava no $TriggerLabel"
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
    # why: as tres chaves so funcionam juntas. A tecla repetida amarra alcance,
    # camera e alvo no mesmo gesto, e o AsToggle=0 faz valer enquanto segura.
    # Em 1 viraria liga/desliga e a combinacao quebra.
    range = @{
      Label    = 'Alcance de ataque, fixar camera e alvejar campeoes'
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
  Write-Host "  backup criado: $(Split-Path $backupPath -Leaf)"
}

function Set-IniSetting {
  param([string]$Path, [string]$Section, [string]$Key, [string]$Value)

  # why: arquivo ausente significa que o cliente nunca gravou config. Criar um do zero
  # produziria arquivo sem .bak, que a opcao 2 nao saberia desfazer
  if (-not (Test-Path -LiteralPath $Path)) {
    Write-Host "  $(Split-Path $Path -Leaf) ausente, ignorado"
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
    Write-Host "  PersistedSettings.json ausente, ignorado"
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

function Invoke-AdvancedMode {
  Write-Host "  Modo Avancado"
  Write-Host "  ------------------------------------------------"
  Write-Host "  O Modo Teamfight usa o Espaco como tecla do combo."
  Write-Host ""
  Write-Host "  Fora da lista: C e N, ja usadas no combo, M abre o mouse e Esc cancela."
  Write-Host "  Vale letra, numero, F1 a F12, espaco, tab ou botao extra de mouse."
  Write-Host ""

  $wantsSwap = Read-Answer -Question '  Trocar o Espaco por outra tecla? (S/n): '

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
  Write-Host "Cancelado. Nada foi alterado."
}

function Read-TriggerUntilConfirmed {
  # why: a escolha repete ate confirmar, e nada e escrito antes disso. Assim uma tecla
  # errada nunca vira alteracao de arquivo, que a opcao 2 teria de desfazer depois
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
  # why: tecla fora da lista so repete a pergunta, e o Esc e a unica saida. Sem isso
  # errar a tecla encerraria o assistente, confundindo "escolhi errado" com "desisti"
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
  Write-Host "  Pressione a tecla desejada."
  Write-Host "  [M] abre os botoes de mouse, [Esc] cancela."
  Write-Host ""
  Write-Host -NoNewline "  Tecla: "

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
    Write-Host "  Tecla nao suportada. Vale letra, numero, F1 a F12, espaco, tab ou mouse."
    $unsupported = $null
    return $unsupported
  }

  if (Test-ReservedToken -Token $Token) {
    Write-Host ""
    Write-Host "  $Token ja e tecla do proprio combo. O par colapsaria numa tecla so."
    $reserved = $null
    return $reserved
  }

  # why: o ReadKey usa NoEcho, entao sem esse Write-Host a linha do prompt fica aberta
  # e a pergunta seguinte sai grudada nela
  $label = ConvertTo-KeyLabel -Token $Token
  Write-Host $label

  $candidate = [pscustomobject]@{ Token = $Token; Label = $label }
  return $candidate
}

# why: allowlist estreita de proposito. A grafia dos tokens do LoL so e conhecida com
# certeza para letra, digito, F1-F12, espaco e tab. Aceitar o resto gravaria um bind
# que o jogo ignora em silencio, e o usuario culparia o script
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
  Write-Host "  Esquerdo, direito e scroll ficam fora: o jogo ja usa os tres."
  Write-Host "  Escolha o botao extra, entre 4 e 9. Mouse comum tem 4 e 5."
  Write-Host ""
  Write-Host -NoNewline "  Botao: "

  $pressed = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
  $chosen = "$($pressed.Character)"
  Write-Host $chosen

  if ($chosen -notmatch $extraMouseButtonPattern) {
    $invalid = $null
    return $invalid
  }

  # why: o LoL grava botao de mouse com B maiusculo, "[Button 4]", diferente das teclas
  # de teclado, que ficam minusculas. Nao e descuido de grafia, e o formato do arquivo
  $buttonToken = "[Button $chosen]"
  return $buttonToken
}

function Test-ReservedToken {
  param([string]$Token)

  # why: [c] e [n] ja sao as modificadoras do combo. Escolher uma delas geraria
  # evtShowCharacterMenu=[c],[c], e um par de teclas iguais vira uma tecla so
  $reservedTokens = @('[c]', '[n]')
  $isReserved = $reservedTokens -contains $Token
  return $isReserved
}

function ConvertTo-KeyLabel {
  param([string]$Token)

  $bareName = $Token.Trim('[', ']')

  if ($bareName -eq 'space') {
    $spaceLabel = 'Espaco'
    return $spaceLabel
  }

  if ($bareName -like 'Button *') {
    $buttonLabel = "Botao $($bareName.Split(' ')[-1]) do mouse"
    return $buttonLabel
  }

  $upperLabel = $bareName.ToUpper()
  return $upperLabel
}

function Confirm-Trigger {
  param($Candidate)

  # why: o conflito entra na propria confirmacao. Perguntar "usa mesmo assim" e depois
  # "confirma" seriam duas perguntas para a mesma decisao
  Show-KeyConflict -Token $Candidate.Token

  Write-Host ""
  Write-Host "  [S] mapear no $($Candidate.Label)   [N] escolher outra tecla   [Esc] cancelar"

  $answer = Read-Answer -Question '  Confirma? (S/n): '
  return $answer
}

function Show-KeyConflict {
  param([string]$Token)

  $conflicts = @(Find-KeyConflict -Token $Token)

  if ($conflicts.Count -eq 0) {
    return
  }

  Write-Host ""
  Write-Host "  Atencao: essa tecla ja esta em uso no input.ini:"

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

  # why: as tres chaves do combo recebem a tecla nova de proposito, entao aparecer
  # nelas nao e conflito. Sem essa exclusao o aviso dispararia contra o proprio script
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

  # why: o LoL separa teclas por virgula na mesma chave, entao comparar a linha inteira
  # daria falso positivo: [c] casaria dentro de [c],[space]
  $boundTokens = @($Line.Substring($separatorIndex + 1).Split(',') | ForEach-Object { $_.Trim() })
  $hasToken = $boundTokens -contains $Token
  return $hasToken
}

# why: uma tecla so em toda pergunta, e o Esc cancela em qualquer uma delas. Com
# Read-Host cada pergunta exigiria Enter e nenhuma enxergaria o Esc, entao a forma de
# desistir mudaria de tela para tela
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

  # why: Enter vale sim, que e o padrao anunciado no (S/n) de cada pergunta
  if ($PressedKey.VirtualKeyCode -eq $enterKeyCode) {
    return $answerYes
  }

  $character = "$($PressedKey.Character)"

  if ($character -imatch '^[sy]$') {
    return $answerYes
  }

  if ($character -imatch '^n$') {
    return $answerNo
  }

  # why: tecla fora das opcoes nao decide nada, entao a pergunta fica aberta
  $ignored = $null
  return $ignored
}

function Invoke-TeamfightMode {
  param([string]$TriggerKey = '[space]', [string]$TriggerLabel = 'Espaco')

  # why: passo unico e deliberado, garante que todo .bak seja a copia pre-alteracao,
  # sem estado intermediario para o usuario decifrar ao voltar atras
  $presets = Get-HotkeyPresets -TriggerKey $TriggerKey -TriggerLabel $TriggerLabel
  $orderedPresets = @($presets.zoom, $presets.camera, $presets.range)
  $persistedPath = Join-Path $configDirectory 'PersistedSettings.json'

  Backup-ConfigFile -Path $persistedPath

  foreach ($preset in $orderedPresets) {
    Write-Host "  $($preset.Label)"
    Invoke-Preset -Preset $preset -PersistedPath $persistedPath
  }

  Write-Host ""
  Write-Host "OK - Modo Teamfight aplicado"
  Write-Host "Feche o modo treino e abra de novo para recarregar as configuracoes."
}

function Invoke-Preset {
  param([hashtable]$Preset, [string]$PersistedPath)

  foreach ($setting in $Preset.Settings) {
    Write-IniTarget -Setting $setting
    Write-PersistedTarget -Setting $setting -PersistedPath $PersistedPath
  }
}

# why: nem toda chave mora nos dois arquivos. O destino que o preset nao declara
# e pulado, senao a chave seria criada no arquivo errado e o cliente a ignoraria
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
    Write-Host "Nenhum backup .bak encontrado em $configDirectory"
    exit 3
  }

  foreach ($backup in $backups) {
    $originalPath = $backup.FullName -replace '\.bak$', ''
    Copy-Item -LiteralPath $backup.FullName -Destination $originalPath -Force
    Write-Host "  restaurado: $(Split-Path $originalPath -Leaf)"
  }

  Write-Host ""
  Write-Host "OK - arquivos originais restaurados"
  Write-Host "Feche o modo treino e abra de novo para recarregar as configuracoes."
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
