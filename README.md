<div align="center">
  <img src="assets/img/lol.png" alt="league-of-legends-teamfight-mode" width="480">
  <h1 align="center">League Of Legends - Modo Teamfight</h1>
  <p align="center">
    Atalhos de teclado do League of Legends que o cliente não deixa configurar pela interface.<br>
    Menos misclick, mais leitura de luta.
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

Duas configurações do League of Legends não aparecem no menu de opções, e só mudam editando arquivo. Juntas elas formam o que aqui chamamos de **Modo Teamfight**: o scroll do mouse para de dar zoom sem você pedir, e o `Espaço` passa a exibir o alcance de ataque, fixar a camera no campeão e mirar só campeões, tudo no mesmo gesto.

Menos camera girando por engano no meio da briga, e mais informação na tela na hora de decidir se troca dano ou recua.

Este repositório traz as duas formas de aplicar. O `.bat` faz tudo de uma vez e guarda um backup antes de tocar em qualquer coisa. O passo a passo manual mostra exatamente o que muda e onde, para quem prefere conferir cada linha.

> [!IMPORTANT]
> **Isto não é script de jogo.** No League, "script" quer dizer automatizar jogada, e isso é proibido e dá banimento.
>
> Aqui não tem nada disso. O que muda são dois arquivos de configuração, os mesmos que o cliente grava sozinho quando você mexe nas opções. Nada roda durante a partida, nada lê a memória do jogo, nada joga no seu lugar.
>
> O `.bat` escreve exatamente as linhas que você escreveria no Bloco de Notas. O passo a passo manual está logo abaixo, e serve para você conferir cada uma antes de rodar qualquer coisa.

## O que o Modo Teamfight faz

<img src="assets/img/jinx-compact.gif" alt="Jinx tei-tei pow-pow" width="384">

**Aperta `Espaço`, modo luta.** Alcance de ataque na tela, camera fixa no campeão e ataque mirando só campeões.

**Solta `Espaço`, modo normal.** Camera solta, alvos gerais e sem alcance na tela.

E o scroll do mouse para de dar zoom, o tempo todo.

<details>
<summary><b>Os detalhes do Modo Teamfight</b></summary>
<br>

**Zoom travado no scroll.** No meio da luta o dedo esbarra no scroll sem querer. A camera dá zoom e você passa a enxergar menos do campo. Com o `RollerButtonSpeed` em `0`, o scroll para de mexer no zoom. Diferente das outras três chaves, essa não depende do `Espaço`.

**Alcance, camera e alvo no `Espaço`.** Por padrão, `C` mostra o alcance de ataque e `Espaço` fixa a camera. Saber o limite do campeão ajuda a decidir quando trocar dano e quando recuar, e eu jogo com a tela solta, então vale juntar os dois no mesmo gesto.

O jogo guarda cada atalho como uma linha `nome=valor` no arquivo de configuração. O nome é o evento, o valor é a tecla que dispara. São três linhas, e `[space]` é o `Espaço`:

| Chave | Valor | O que faz |
| :-- | :-- | :-- |
| `evtShowCharacterMenu` | `[c],[space]` | Exibe o alcance de ataque |
| `evtChampionOnly` | `[n],[space]` | Faz o ataque mirar só campeões, ignorando minions |
| `TargetChampionsOnlyAsToggle` | `0` | Faz o alvejar valer enquanto a tecla estiver pressionada |

Nenhuma das três mexe na camera: o `Espaço` já é a tecla dela, e as duas primeiras entram como tecla secundária. O `TargetChampionsOnlyAsToggle=0` faz o efeito valer enquanto você segura, em vez de virar liga e desliga.

</details>

<details>
<summary><b>Conceitos fundamentais</b></summary>
<br>

| Conceito | O que é |
| :-- | :-- |
| `input.ini` | Arquivo de texto com os atalhos, em formato `chave=valor` agrupado por seção |
| `PersistedSettings.json` | Espelho das configurações em JSON, que o cliente lê ao iniciar |
| `RollerButtonSpeed` | Velocidade do zoom no scroll. Em `0`, o scroll para de dar zoom |
| `evtShowCharacterMenu` | Evento do alcance de ataque. Aceita mais de uma tecla, separadas por vírgula |
| `evtChampionOnly` | Evento que faz o ataque mirar só campeões, ignorando minions |
| `TargetChampionsOnlyAsToggle` | Modo do alvejar. Em `0` vale enquanto segura, em `1` liga e desliga |
| **cliente do LoL** | O programa da Riot que abre antes da partida. É ele que lê e grava esses arquivos de configuração |
| **modo treino** | Partida solo, sem adversários. Aqui serve para o cliente recarregar os arquivos |
| `.bak` | Cópia do arquivo original, criada antes da primeira edição |

</details>

## Antes de começar

O cliente do LoL lê esses arquivos ao entrar em partida, e reescreve alguns deles ao fechar. Por isso a ordem importa:

| Passo | Quem faz |
| :-- | :-- |
| 1. Abrir o jogo e entrar em **modo treino** | você |
| 2. Minimizar o jogo, sem fechar | você |
| 3. Editar `input.ini` e `PersistedSettings.json` | o `.bat`, ou você no Bloco de Notas |
| 4. Fechar o modo treino e abrir de novo | você |
| 5. Conferir o `Espaço` e o scroll | você |

Sem fechar e reabrir o modo treino, o jogo segue com os valores que carregou antes da edição.

> [!TIP]
> Localize o diretório de instalação do League of Legends.
>
> Por padrão fica em `C:\Riot Games\League of Legends\`. Se você mudou o caminho na instalação, ajuste onde aparecer.

## Modo automático: o `.bat`

**[⬇ Baixar aplica-modo-teamfight.bat](https://github.com/thiagocajadev/league-of-legends-teamfight-mode/releases/latest/download/aplica-modo-teamfight.bat)** · [versão em inglês](https://github.com/thiagocajadev/league-of-legends-teamfight-mode/releases/latest/download/apply-teamfight-mode.bat)

Clique no link, salve o arquivo e dê dois cliques nele. A opção `1`, **Aplicar o Modo Teamfight**, escreve as duas configurações de uma vez.

<details>
<summary><b>Como o <code>.bat</code> funciona</b></summary>
<br>

Abre um menu:

```text
  league-of-legends-teamfight-mode  v2.0.0  @thiagocajadev
  --------------------------------------------------------
  Config: C:\Riot Games\League of Legends\Config

  [1] Aplicar o Modo Teamfight
      zoom travado e alcance, camera e alvo no Espaco
      menos misclick, mais leitura de luta

  [2] Restaurar os arquivos originais (.bak)
  [0] Sair
```

| Opção | O que escreve |
| :-- | :-- |
| `1` | `RollerButtonSpeed=0` e as três chaves de alcance, camera e alvo, nos dois arquivos |
| `2` | Devolve todo `.bak` da pasta `Config` ao lugar de origem |

- **Um passo só, de propósito.** As duas configurações são aplicadas na mesma execução. Assim todo `.bak` é sempre a cópia anterior a qualquer alteração, e não existe estado intermediário para você decifrar se resolver voltar atrás.
- **Backup automático.** Na primeira vez que você roda `1`, cada arquivo tocado ganha um `.bak` ao lado. Rodar de novo não sobrescreve esse backup, senão a cópia "original" viraria cópia do arquivo já modificado.
- **Substitui ou cria a chave.** Se a chave existe, o valor é trocado onde ela estiver. Se não existe, ela é criada na seção certa. Rodar duas vezes não duplica linha.
- **Nunca cria arquivo.** Se o `input.ini` ou o `PersistedSettings.json` não existirem, o `.bat` avisa e pula aquele arquivo. Ele só mexe no que o cliente já gravou.
- **Acha a instalação sozinho.** Com o jogo aberto, o `.bat` lê o caminho do processo em execução, então funciona com o League instalado em qualquer disco ou pasta. Se o jogo estiver fechado, ele tenta o registro da Riot, depois o caminho padrão, e só então pergunta.

Se a pasta `Config` não existir, ele avisa e sai sem escrever nada.

</details>

<details>
<summary><b>Modo manual: alterando arquivos com Bloco de Notas</b></summary>
<br>

Pode editar manualmente, sem problemas. As duas configurações abaixo são o que o `.bat` faz, e chegam no mesmo resultado.

Todos os arquivos ficam em:

```text
C:\Riot Games\League of Legends\Config
```

> [!WARNING]
> Mantenha a estrutura JSON válida. Não remova nem edite outras seções, a menos que saiba o que está fazendo.

### Desativar zoom via scroll do mouse

Abra o `input.ini` no **Bloco de Notas** e adicione ou edite as linhas:

```ini
[MouseSettings]
RollerButtonSpeed=0
```

![Exemplo no input.ini](assets/img/01-exemplo-input-ini.png)
*Exemplo no arquivo input.ini*

Depois abra o `PersistedSettings.json` e adicione ou edite o bloco:

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

### Alcance, camera e alvo no Espaço

No `input.ini`, na seção `[GameEvents]`, adicione ou edite as linhas:

```ini
evtShowCharacterMenu=[c],[space]
evtChampionOnly=[n],[space]
TargetChampionsOnlyAsToggle=0
```

![Exemplo no input.ini](assets/img/03-exemplo-alcance-ataque-input-ini.png)
*Exemplo no arquivo input.ini*

No `PersistedSettings.json`, procure uma chave de cada vez com o buscar do editor (`Ctrl+F`) e deixe os valores assim. Elas ficam espalhadas pelo arquivo, então não espere achar as três em sequência:

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

Salve os dois arquivos e feche o editor.

</details>

## Dicas finais

- Depois de aplicar, feche e reabra o modo treino para o cliente recarregar os arquivos.
- Se algo der errado, rode a opção `2` do `.bat`, **Restaurar os arquivos originais**, que devolve tudo como estava.

## Não gostou? Volte ao padrão

Três caminhos, do mais seguro ao mais bruto:

1. **Restaurar o backup.** Rode a opção `2` do `.bat`, **Restaurar os arquivos originais (.bak)**. Ela devolve todo `.bak` da pasta `Config`, que é o estado exato de antes da primeira execução.
2. **Apagar os arquivos gerados.** Sem backup à mão, apague o `input.ini` e o `PersistedSettings.json` da pasta `Config`. O cliente do LoL recria os dois com os valores padrão ao iniciar.
3. **Restaurar pelo próprio jogo.** Dentro do League, em **Configurações**, existe a opção de restaurar as configurações padrão. Serve para desfazer tudo sem tocar em arquivo nenhum.

Os caminhos `2` e `3` zeram também as outras opções que você tenha ajustado no jogo, não só o Modo Teamfight.

## Referências

- [YouTube: tutorial para desativar o scroll](https://www.youtube.com/watch?v=db7sTv3zYAg)
- [YouTube: tutorial para sempre exibir o alcance de ataque](https://www.youtube.com/watch?v=hTs4veZcbo8)
- [Reddit: conversa sobre desativar o scroll](https://www.reddit.com/r/leagueoflegends/comments/tvib4a/disable_zooming_inout_with_mouse_scroll_wheel/?rdt=56391)
- [Reddit: exibir alcance do ataque](https://www.reddit.com/r/ADCMains/comments/1ejlzg5/comment/lgh39ku/?tl=pt-br)

## Licença

MIT, thiagocajadev.
