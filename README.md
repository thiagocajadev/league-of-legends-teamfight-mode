<div align="center">
  <img src="assets/img/lol.png" alt="league-of-legends-hotkeys" width="480">
  <h1 align="center">League Of Legends - Atalhos do Jogo</h1>
  <p align="center">
    Atalhos de teclado do League of Legends que o cliente não deixa configurar pela interface.<br>
    O passo a passo para fazer na mão, e um <code>.bat</code> que faz por você.
  </p>
  <a href="https://learn.microsoft.com/windows/"><img src="https://img.shields.io/badge/windows-10%20%7C%2011-0078D4?style=flat-square&logo=windows&logoColor=white" alt="Windows" /></a>
  <a href="https://learn.microsoft.com/windows-server/administration/windows-commands/windows-commands"><img src="https://img.shields.io/badge/batch-cmd-4D4D4D?style=flat-square&logo=windowsterminal&logoColor=white" alt="Batch" /></a>
  <a href="https://learn.microsoft.com/powershell/"><img src="https://img.shields.io/badge/powershell-5.1-5391FE?style=flat-square&logo=powershell&logoColor=white" alt="PowerShell" /></a>
  <a href="https://www.leagueoflegends.com"><img src="https://img.shields.io/badge/league%20of%20legends-config-C89B3C?style=flat-square&logo=leagueoflegends&logoColor=white" alt="League of Legends" /></a>
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="Licença MIT" /></a>
  <p align="center">
    <b>Português</b> · <a href="README.en.md">English</a>
  </p>
</div>

<br>

*Créditos da imagem: [Epic Games](https://store.epicgames.com/en-US/p/league-of-legends)*

Olá player de **Lolzinho**.

Duas configurações do League of Legends não aparecem no menu de opções, e só mudam editando arquivo. A primeira desativa o zoom no scroll do mouse. A segunda junta três atalhos em um: exibir o alcance de ataque, fixar a camera no campeão e mirar só campeões, tudo com o `Espaço`.

Este repositório traz as duas formas de aplicar. O passo a passo manual mostra o que muda e onde. O `.bat` faz a mesma edição sozinho, e guarda um backup antes de tocar em qualquer coisa.

> [!IMPORTANT]
> **Isto não é script de jogo.** No League, "script" quer dizer automatizar jogada, e isso é proibido e dá banimento.
>
> Aqui não tem nada disso. O que muda são dois arquivos de configuração, os mesmos que o cliente grava sozinho quando você mexe nas opções. Nada roda durante a partida, nada lê a memória do jogo, nada joga no seu lugar.
>
> O `.bat` escreve exatamente as linhas que você escreveria no Bloco de Notas. O passo a passo manual está logo abaixo, e serve para você conferir cada uma antes de rodar qualquer coisa.

## Conceitos fundamentais

| Conceito | O que é |
| :-- | :-- |
| `input.ini` | Arquivo de texto com os atalhos, em formato `chave=valor` agrupado por seção |
| `PersistedSettings.json` | Espelho das configurações em JSON, que o cliente lê ao iniciar |
| `RollerButtonSpeed` | Velocidade do zoom no scroll. Em `0`, o scroll para de dar zoom |
| `evtShowCharacterMenu` | Evento do alcance de ataque. Aceita mais de uma tecla, separadas por vírgula |
| `evtChampionOnly` | Evento que faz o ataque mirar só campeões, ignorando minions |
| `TargetChampionsOnlyAsToggle` | Modo do alvejar. Em `0` vale enquanto segura, em `1` liga e desliga |
| **modo treino** | Partida solo, sem adversários. Aqui serve para o cliente recarregar os arquivos |
| `.bak` | Cópia do arquivo original, criada antes da primeira edição |

## Antes de começar

O cliente lê esses arquivos ao entrar em partida, e reescreve alguns deles ao fechar. Por isso a ordem importa:

| Passo | Quem faz |
| :-- | :-- |
| 1. Abrir o jogo e entrar em **modo treino** | você |
| 2. Minimizar o jogo, sem fechar | você |
| 3. Editar `input.ini` e `PersistedSettings.json` | o `.bat`, ou você no Bloco de Notas |
| 4. Fechar o modo treino e abrir de novo | você |
| 5. Conferir o `C` + `Espaço` e o scroll | você |

Sem fechar e reabrir o modo treino, o jogo segue com os valores que carregou antes da edição.

> [!TIP]
> Localize o diretório de instalação do League of Legends.
>
> Por padrão fica em `C:\Riot Games\League of Legends\`. Se você mudou o caminho na instalação, ajuste onde aparecer.

## Modo automático: o `.bat`

**[⬇ Baixar apply-hotkeys-pt-br.bat](https://github.com/thiagocajadev/league-of-legends-hotkeys/releases/latest/download/apply-hotkeys-pt-br.bat)** · [versão em inglês](https://github.com/thiagocajadev/league-of-legends-hotkeys/releases/latest/download/apply-hotkeys-en.bat)

Clique no link, salve o arquivo e dê dois cliques nele. Abre um menu:

```text
  league-of-legends-hotkeys  v1.1.0  @thiagocajadev
  ---------------------------------------------
  Config: C:\Riot Games\League of Legends\Config

  [1] Desabilitar zoom via scroll do mouse
  [2] Alcance + fixar camera + alvejar campeoes (Espaco)
  [3] Restaurar os arquivos originais (.bak)
  [0] Sair
```

| Opção | O que escreve |
| :-- | :-- |
| `1` | `RollerButtonSpeed=0` no `input.ini` e no `PersistedSettings.json` |
| `2` | As três chaves do alcance, camera e alvo, nos dois arquivos |
| `3` | Devolve todo `.bak` da pasta `Config` ao lugar de origem |

- **Backup automático.** Na primeira vez que você roda `1` ou `2`, cada arquivo tocado ganha um `.bak` ao lado. Rodar de novo não sobrescreve esse backup, senão a cópia "original" viraria cópia do arquivo já modificado.
- **Substitui ou cria a chave.** Se a chave existe, o valor é trocado onde ela estiver. Se não existe, ela é criada na seção certa. Rodar duas vezes não duplica linha.
- **Nunca cria arquivo.** Se o `input.ini` ou o `PersistedSettings.json` não existirem, o `.bat` avisa e pula aquele arquivo. Ele só mexe no que o cliente já gravou.
- **Acha a instalação sozinho.** Com o jogo aberto, o `.bat` lê o caminho do processo em execução, então funciona com o League instalado em qualquer disco ou pasta. Se o jogo estiver fechado, ele tenta o registro da Riot, depois o caminho padrão, e só então pergunta.

Se a pasta `Config` não existir, ele avisa e sai sem escrever nada.

## Modo manual

Pode editar manualmente, sem problemas. As duas configurações abaixo são o que o `.bat` faz, e chegam no mesmo resultado.

## Desativar zoom via scroll do mouse

No meio da luta o dedo esbarra no scroll sem querer. A camera dá zoom e você passa a enxergar menos do campo. Com o `RollerButtonSpeed` em `0`, o scroll para de mexer no zoom.

<details>
<summary>Passo 1: editando o <code>input.ini</code></summary>
<br>

1. Navegue até o diretório:

```text
C:\Riot Games\League of Legends\Config
```

2. Abra o `input.ini` em um editor de texto, como o **Bloco de Notas**.

3. Adicione ou edite as seguintes linhas:

```ini
[MouseSettings]
RollerButtonSpeed=0
```

![Exemplo no input.ini](assets/img/01-exemplo-input-ini.png)
*Exemplo no arquivo input.ini*

4. Salve o arquivo e feche o editor.

</details>

<details>
<summary>Passo 2: editando o <code>PersistedSettings.json</code></summary>
<br>

1. Navegue até o diretório:

```text
C:\Riot Games\League of Legends\Config
```

2. Abra o `PersistedSettings.json` em um editor de texto.

3. Adicione ou edite o seguinte bloco:

```json
{
  "name": "MouseSettings",
  "settings": [
    {
      "name": "RollerButtonSpeed",
      "value": "0"
    }
  ]
}
```

![Exemplo no PersistedSettings.json](assets/img/02-exemplo-persisted-settings.png)
*Exemplo no arquivo PersistedSettings.json*

> [!WARNING]
> Mantenha a estrutura JSON válida. Não remova nem edite outras seções, a menos que saiba o que está fazendo.

4. Salve o arquivo e feche o editor.

</details>

## Exibir alcance de ataque, fixar a camera e alvejar campeões

![Jinx tei-tei pow-pow](assets/img/jinx-compact.gif)

Segure `Espaço` e tenha alcance, camera fixa e foco em campeões. Solte `Espaço` e volta tudo ao normal.

### E como isso funciona

Por padrão, `C` mostra o **alcance de ataque** e `Espaço` **fixa a camera**. Saber o limite do campeão ajuda a decidir quando trocar dano e quando recuar, e eu jogo com a tela solta, então vale juntar os dois no mesmo gesto.

O jogo guarda cada atalho como uma linha `nome=valor` no arquivo de configuração. O nome é o evento, o valor é a tecla que dispara. São três linhas, e `[space]` é o `Espaço`:

| Chave | Valor | O que faz |
| :-- | :-- | :-- |
| `evtShowCharacterMenu` | `[c],[space]` | Exibe o alcance de ataque |
| `evtChampionOnly` | `[n],[space]` | Faz o ataque mirar só campeões, ignorando minions |
| `TargetChampionsOnlyAsToggle` | `0` | Faz o alvejar valer enquanto a tecla estiver pressionada |

Nenhuma das três mexe na camera: o `Espaço` já é a tecla dela, e as duas primeiras entram como tecla secundária. O resultado:

- **Segurar `Espaço`**: fixa a camera, alveja só campeões e mostra o alcance.
- **Soltar**: volta ao padrão, camera solta, alvos gerais e sem alcance na tela.

<details>
<summary>Passo 1: editando o <code>input.ini</code></summary>
<br>

1. Navegue até o diretório:

```text
C:\Riot Games\League of Legends\Config
```

2. Abra o `input.ini` em um editor de texto.

3. Na seção `[GameEvents]`, adicione ou edite as linhas:

```ini
evtShowCharacterMenu=[c],[space]
evtChampionOnly=[n],[space]
TargetChampionsOnlyAsToggle=0
```

![Exemplo no input.ini](assets/img/03-exemplo-alcance-ataque-input-ini.png)
*Exemplo no arquivo input.ini*

4. Salve o arquivo e feche o editor.

</details>

<details>
<summary>Passo 2: editando o <code>PersistedSettings.json</code></summary>
<br>

1. Navegue até o diretório:

```text
C:\Riot Games\League of Legends\Config
```

2. Abra o `PersistedSettings.json` em um editor de texto.

3. Procure uma chave de cada vez com o buscar do editor (`Ctrl+F`) e deixe os valores assim. Elas ficam espalhadas pelo arquivo, então não espere achar as três em sequência:

```json
{
    "name": "TargetChampionsOnlyAsToggle",
    "value": "0"
},
{
    "name": "evtChampionOnly",
    "value": "[n],[space]"
},
{
    "name": "evtShowCharacterMenu",
    "value": "[c],[space]"
},
```

![Exemplo no PersistedSettings.json](assets/img/04-exemplo-alcance-ataque-persisted-settings.png)
*Exemplo no arquivo PersistedSettings.json*

> [!WARNING]
> Mantenha a estrutura JSON válida. Não remova nem edite outras seções, a menos que saiba o que está fazendo.

4. Salve o arquivo e feche o editor.

</details>

## Dicas finais

- Depois de qualquer configuração, feche e reabra o modo treino para o cliente recarregar os arquivos.
- Se algo der errado, rode a opção `3` do `.bat`, que devolve os originais.
- Se você não tiver backup, apague o `input.ini` e o `PersistedSettings.json`. O cliente recria os dois com os valores padrão ao iniciar.

## Referências

- [YouTube: tutorial para desativar o scroll](https://www.youtube.com/watch?v=db7sTv3zYAg)
- [YouTube: tutorial para sempre exibir o alcance de ataque](https://www.youtube.com/watch?v=hTs4veZcbo8)
- [Reddit: conversa sobre desativar o scroll](https://www.reddit.com/r/leagueoflegends/comments/tvib4a/disable_zooming_inout_with_mouse_scroll_wheel/?rdt=56391)
- [Reddit: exibir alcance do ataque](https://www.reddit.com/r/ADCMains/comments/1ejlzg5/comment/lgh39ku/?tl=pt-br)

## Licença

MIT, thiagocajadev.
