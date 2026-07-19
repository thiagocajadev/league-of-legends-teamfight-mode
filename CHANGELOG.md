# Changelog

Todas as mudanças relevantes deste projeto são registradas aqui.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/),
e o versionamento segue [Semantic Versioning](https://semver.org/lang/pt-BR/).

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

[1.0.0]: https://github.com/thiagocajadev/league-of-legends-hotkeys/releases/tag/v1.0.0
[0.2.0]: https://github.com/thiagocajadev/league-of-legends-hotkeys/compare/d9883d9...86a2bb2
[0.1.0]: https://github.com/thiagocajadev/league-of-legends-hotkeys/commits/d9883d9
