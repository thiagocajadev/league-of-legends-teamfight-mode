# Changelog

Todas as mudanças relevantes deste projeto são registradas aqui.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e o versionamento segue [Semantic Versioning](https://semver.org/lang/pt-BR/).

## [2.0.2] - 2026-07-20

### Changed

- Link do crédito da imagem passou do site institucional da Riot para o site do próprio jogo, no idioma de cada README: `leagueoflegends.com/pt-br` no pt-BR e `/en-us` no inglês.

## [2.0.1] - 2026-07-20

### Fixed

- Crédito da imagem apontava para a **Epic Games**, que só distribui o League na loja dela. A arte é da **Riot Games**, agora creditada corretamente e com link para o site oficial.

### Changed

- Créditos da imagem foram para dentro do bloco centralizado, logo abaixo da arte que creditam, em `<sub>`. Antes ficavam soltos à esquerda depois do cabeçalho, distantes da imagem. Usado `<sub>` e não `<small>`, que o sanitizador de HTML do GitHub não garante, e `<a href>` no lugar de link markdown, que não é processado dentro de bloco HTML.

## [2.0.0] - 2026-07-19

### Added

- Nome para o conjunto de configurações: **Modo Teamfight** no pt-BR, **Teamfight Mode** no inglês. Antes as duas configs eram descritas só pelo que faziam, sem um nome que a pessoa pudesse procurar ou divulgar.
- Seção "Não gostou? Volte ao padrão" nos dois READMEs, com os três caminhos de reversão: restaurar o `.bak`, apagar os arquivos gerados, ou usar a opção de restaurar configurações padrão dentro do jogo.
- Resumo de duas linhas antes dos detalhes: apertar `Espaço` liga, soltar volta ao normal. O detalhamento técnico foi para um bloco recolhível.

### Changed

- **BREAKING**: o menu passou a ter um passo só. A opção `1` aplica zoom e atalhos na mesma execução, e a antiga opção `3` de restaurar virou `2`. Aplicar tudo de uma vez garante que todo `.bak` seja a cópia anterior a qualquer alteração, sem estado intermediário para o usuário decifrar ao voltar atrás.
- **BREAKING**: repositório renomeado de `league-of-legends-hotkeys` para `league-of-legends-teamfight-mode`.
- **BREAKING**: os scripts perderam o sufixo de idioma e passaram a se identificar pelo próprio nome. `apply-hotkeys-pt-br.bat` virou `aplica-modo-teamfight.bat`, e `apply-hotkeys-en.bat` virou `apply-teamfight-mode.bat`. Nenhuma release havia sido publicada, então nenhum link de download existente quebra.
- `Invoke-Preset` deixou de fazer o backup do `PersistedSettings.json` e de imprimir o encerramento. Isso subiu para `Invoke-TeamfightMode`, que orquestra os dois presets e garante um backup único antes do laço.
- Conceitos fundamentais, funcionamento do `.bat` e passo a passo manual viraram blocos recolhíveis. O gif e o link de download ficaram fora deles, por serem o que prende o leitor e o que converte.
- Gif da Jinx ampliado para 384px de largura, 20% acima do tamanho nativo.

### Fixed

- Comentário `# why:` em `Set-IniSetting` citava a opção `3` do menu, que deixou de existir na renumeração.
- Régua de tracinhos do cabeçalho do menu acompanhava o nome antigo e ficou curta depois da renomeação.

## [1.1.0] - 2026-07-19

### Added

- `bat/apply-hotkeys-en.bat`, espelho em inglês do script. Mesma engine PowerShell e mesmos exit codes do pt-BR, com as mensagens de menu traduzidas. Reverte a decisão anterior de manter só pt-BR.
- Créditos embutidos nos dois `.bat`, com versão, `@thiagocajadev` e URL do repositório, visíveis no topo do arquivo e no cabeçalho do menu.
- `.github/workflows/release.yml`, que dispara em push de tag `v*`, cria o release com os dois `.bat` anexados e apaga a release anterior. Usa o `gh` nativo do runner, sem action de terceiro.
- Guard de versão no CI, que falha o workflow se o cabeçalho de versão dentro dos `.bat` não bater com a tag empurrada.

### Changed

- Os `.bat` passaram a viver em `bat/`, com sufixo de idioma no nome. A pasta não se chama `script` de propósito, já que o README nega explicitamente que o projeto seja script de jogo.
- Links de download do README apontam para `releases/latest/download/`, que baixa o arquivo direto em um clique e não precisa ser reescrito a cada versão. Antes apontavam para o arquivo no repositório, que abre a página de código.
- Seção de alcance de ataque reescrita nos dois READMEs. Ganhou resumo de uma linha antes da explicação, e a tabela de chaves passou a ser introduzida em linguagem não técnica.
- Documentado que o `Espaço` já é a tecla de camera do jogo e que as duas primeiras chaves entram como tecla secundária. O texto anterior creditava a camera às chaves, que não a controlam.
- Documentado o que acontece ao soltar o `Espaço`: o alvejar desliga junto, devolvendo o ataque livre para farmar.

## [1.0.0] - 2026-07-19

### Added

- `apply-hotkeys.bat`, menu em batch com motor de upsert em PowerShell no mesmo arquivo. Aplica as configurações em `input.ini` e `PersistedSettings.json`, cria backup `.bak` na primeira execução e restaura os originais.
- Detecção automática da pasta de instalação. Lê o caminho do processo em execução, com fallback para a metadata da Riot, o caminho padrão e, por último, pergunta ao usuário.
- Opção `1` do menu, que desabilita o zoom pelo scroll do mouse via `RollerButtonSpeed=0`.
- Opção `2` do menu, que aplica as três chaves de alcance de ataque, camera fixa e alvejar campeões. As três funcionam em conjunto e são aplicadas juntas.
- Opção `3` do menu, que restaura todo `.bak` da pasta `Config`.
- `README.en.md`, espelho do guia em inglês, com seletor de idioma no topo dos dois arquivos.
- `LICENSE` MIT.
- Aviso explícito de que o projeto não é script de jogo. O escopo é edição de arquivo de configuração, reproduzível à mão.

### Changed

- README padronizado com bloco central, badges, tabela de conceitos e seção de pré-requisito. Título único, sem os três `H1` soltos da versão anterior.
- Passo a passo do modo treino documentado antes das instruções de configuração, incluindo o fechar e reabrir que recarrega os arquivos.
- Voz do README revisada. Os métodos alternativos viraram passos em sequência, já que as duas edições são aplicadas juntas.

### Fixed

- Upsert passou a procurar a chave no arquivo inteiro antes de criá-la na seção declarada. Sem isso, uma chave guardada em seção diferente da esperada ganharia uma segunda cópia, que o cliente ignoraria.
- `input.ini` deixou de ser criado do zero quando ausente. O arquivo criado não teria `.bak`, e a restauração não saberia desfazê-lo. Agora o comportamento é igual ao do JSON: avisa e pula.
- Corrigido `if "%OPCAO%"=="1" set VAR=x & goto destino` no batch, que executava o `goto` em qualquer opção, porque o `&` é resolvido em tempo de parse.

## [0.2.0] - 2025-09-02

> Versão reconstruída a partir do histórico do git. Não houve tag na época.

### Added

- Seção de alcance de ataque, com `evtShowCharacterMenu=[c],[space]` combinando a exibição do alcance com a camera fixa.
- Imagens de exemplo da configuração de alcance no `input.ini` e no `PersistedSettings.json`.
- Gif da Jinx na abertura da seção.
- Referências de vídeo e as discussões do Reddit sobre as duas configurações.

### Changed

- Título passou a cobrir o escopo maior do guia, já que o documento deixou de tratar só do zoom.
- Diretório de instalação virou um callout `[!TIP]` no topo, deixando de ser uma seção do corpo.

## [0.1.0] - 2024-11-17

### Added

- Guia para desativar o zoom pelo scroll do mouse via `RollerButtonSpeed=0`.
- Os dois caminhos de edição, `input.ini` e `PersistedSettings.json`, com imagens de exemplo.
- Seção de dicas finais, com a orientação de apagar os arquivos para o cliente recriá-los.

[2.0.0]: https://github.com/thiagocajadev/league-of-legends-teamfight-mode/releases/tag/v2.0.0
[1.1.0]: https://github.com/thiagocajadev/league-of-legends-teamfight-mode/releases/tag/v1.1.0
[1.0.0]: https://github.com/thiagocajadev/league-of-legends-teamfight-mode/releases/tag/v1.0.0
[0.2.0]: https://github.com/thiagocajadev/league-of-legends-teamfight-mode/compare/d9883d9...86a2bb2
[0.1.0]: https://github.com/thiagocajadev/league-of-legends-teamfight-mode/commits/d9883d9
