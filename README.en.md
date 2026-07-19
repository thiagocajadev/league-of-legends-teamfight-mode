<div align="center">
  <img src="assets/img/lol.png" alt="league-of-legends-hotkeys" width="480">
  <h1 align="center">League Of Legends - Game Hotkeys</h1>
  <p align="center">
    League of Legends keybinds the client will not let you set from the interface.<br>
    The manual walkthrough, and a <code>.bat</code> that does it for you.
  </p>
  <a href="https://learn.microsoft.com/windows/"><img src="https://img.shields.io/badge/windows-10%20%7C%2011-0078D4?style=flat-square&logo=windows&logoColor=white" alt="Windows" /></a>
  <a href="https://learn.microsoft.com/windows-server/administration/windows-commands/windows-commands"><img src="https://img.shields.io/badge/batch-cmd-4D4D4D?style=flat-square&logo=windowsterminal&logoColor=white" alt="Batch" /></a>
  <a href="https://learn.microsoft.com/powershell/"><img src="https://img.shields.io/badge/powershell-5.1-5391FE?style=flat-square&logo=powershell&logoColor=white" alt="PowerShell" /></a>
  <a href="https://www.leagueoflegends.com"><img src="https://img.shields.io/badge/league%20of%20legends-config-C89B3C?style=flat-square&logo=leagueoflegends&logoColor=white" alt="League of Legends" /></a>
  <a href="./LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue?style=flat-square" alt="MIT License" /></a>
  <p align="center">
    <a href="README.md">Português</a> · <b>English</b>
  </p>
</div>

<br>

*Image credits: [Epic Games](https://store.epicgames.com/en-US/p/league-of-legends)*

Hey there, League player.

Two League of Legends settings never show up in the options menu, and the only way to change them is by editing a file. The first one disables zoom on the mouse scroll. The second one merges three shortcuts into one: show the attack range, lock the camera on your champion, and target champions only, all on `Space`.

This repository covers both ways to apply them. The manual walkthrough shows what changes and where. The `.bat` makes the same edits on its own, and keeps a backup before touching anything.

> [!IMPORTANT]
> **This is not a game script.** In League, "script" means automating gameplay, which is against the rules and gets you banned.
>
> None of that happens here. What changes is two configuration files, the same ones the client writes on its own when you touch the options. Nothing runs during the match, nothing reads game memory, nothing plays for you.
>
> The `.bat` writes the exact lines you would type in Notepad. The manual walkthrough sits right below, so you can check every one of them before running anything.

## Fundamental concepts

| Concept | What it is |
| :-- | :-- |
| `input.ini` | Text file holding the keybinds, as `key=value` grouped into sections |
| `PersistedSettings.json` | JSON mirror of the settings, which the client reads on startup |
| `RollerButtonSpeed` | Scroll zoom speed. At `0`, the scroll wheel stops zooming |
| `evtShowCharacterMenu` | Attack range event. Takes more than one key, separated by a comma |
| `evtChampionOnly` | Event that makes attacks target champions only, ignoring minions |
| `TargetChampionsOnlyAsToggle` | Targeting mode. At `0` it holds, at `1` it toggles on and off |
| **Practice Tool** | Solo game with no opponents. Here it serves to make the client reload the files |
| `.bak` | Copy of the original file, created before the first edit |

## Before you start

The client reads these files when a game starts, and rewrites some of them on exit. That is why the order matters:

| Step | Who does it |
| :-- | :-- |
| 1. Open the game and enter **Practice Tool** | you |
| 2. Minimize the game, without closing it | you |
| 3. Edit `input.ini` and `PersistedSettings.json` | the `.bat`, or you in Notepad |
| 4. Close Practice Tool and open it again | you |
| 5. Check `C` + `Space` and the scroll wheel | you |

Without closing and reopening Practice Tool, the game keeps the values it loaded before the edit.

> [!TIP]
> Find your League of Legends install folder.
>
> The default is `C:\Riot Games\League of Legends\`. If you changed the path during installation, adjust it wherever it appears.

## Automatic mode: the `.bat`

**[⬇ Download apply-hotkeys-en.bat](https://github.com/thiagocajadev/league-of-legends-hotkeys/releases/latest/download/apply-hotkeys-en.bat)** · [Portuguese version](https://github.com/thiagocajadev/league-of-legends-hotkeys/releases/latest/download/apply-hotkeys-pt-br.bat)

Click the link, save the file and double click it. A menu opens:

```text
  league-of-legends-hotkeys  v1.1.0  @thiagocajadev
  ---------------------------------------------
  Config: C:\Riot Games\League of Legends\Config

  [1] Disable zoom via mouse scroll
  [2] Attack range + lock camera + target champions (Space)
  [3] Restore the original files (.bak)
  [0] Exit
```

| Option | What it writes |
| :-- | :-- |
| `1` | `RollerButtonSpeed=0` in `input.ini` and in `PersistedSettings.json` |
| `2` | The three keys for range, camera and targeting, in both files |
| `3` | Restores every `.bak` in the `Config` folder back to its original name |

- **Automatic backup.** The first time you run `1` or `2`, every file it touches gets a `.bak` next to it. Running again does not overwrite that backup, otherwise the "original" copy would become a copy of the already modified file.
- **Replaces or creates the key.** If the key exists, the value is replaced wherever it sits. If it does not exist, it is created in the right section. Running twice does not duplicate a line.
- **Never creates a file.** If `input.ini` or `PersistedSettings.json` are missing, the `.bat` says so and skips that file. It only touches what the client already wrote.
- **Finds the install on its own.** With the game open, the `.bat` reads the path from the running process, so it works with League installed on any drive or folder. With the game closed, it tries the Riot metadata, then the default path, and only then asks.

If the `Config` folder does not exist, it says so and exits without writing anything.

## Manual mode

Editing by hand is fine. The two configurations below are what the `.bat` does, and they reach the same result.

## Disable zoom on mouse scroll

In the middle of a fight your finger bumps the scroll wheel. The camera zooms and you end up seeing less of the field. With `RollerButtonSpeed` at `0`, the scroll wheel stops changing the zoom.

<details>
<summary>Step 1: editing <code>input.ini</code></summary>
<br>

1. Go to the folder:

```text
C:\Riot Games\League of Legends\Config
```

2. Open `input.ini` in a text editor, such as **Notepad**.

3. Add or edit these lines:

```ini
[MouseSettings]
RollerButtonSpeed=0
```

![Example in input.ini](assets/img/01-exemplo-input-ini.png)
*Example inside input.ini*

4. Save the file and close the editor.

</details>

<details>
<summary>Step 2: editing <code>PersistedSettings.json</code></summary>
<br>

1. Go to the folder:

```text
C:\Riot Games\League of Legends\Config
```

2. Open `PersistedSettings.json` in a text editor.

3. Add or edit this block:

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

![Example in PersistedSettings.json](assets/img/02-exemplo-persisted-settings.png)
*Example inside PersistedSettings.json*

> [!WARNING]
> Keep the JSON structure valid. Do not remove or edit other sections unless you know what you are doing.

4. Save the file and close the editor.

</details>

## Show attack range, lock the camera and target champions only

![Jinx tei-tei pow-pow](assets/img/jinx-compact.gif)

Hold `Space` and get range, locked camera and champion focus. Release `Space` and everything goes back to normal.

### And how it works

By default, `C` shows the **attack range** and `Space` **locks the camera**. Knowing your champion's reach helps you decide when to trade damage and when to back off, and I play with the camera unlocked, so it pays to fold both into the same gesture.

The game stores every shortcut as a `name=value` line in the config file. The name is the event, the value is the key that fires it. There are three lines, and `[space]` is the `Space` key:

| Key | Value | What it does |
| :-- | :-- | :-- |
| `evtShowCharacterMenu` | `[c],[space]` | Shows the attack range |
| `evtChampionOnly` | `[n],[space]` | Makes attacks target champions only, ignoring minions |
| `TargetChampionsOnlyAsToggle` | `0` | Makes the targeting hold while the key is pressed |

None of the three touches the camera: `Space` is already the camera key, and the first two come in as a secondary binding. The result:

- **Hold `Space`**: locks the camera, targets champions only and shows the range.
- **Release**: back to default, free camera, any target, no range on screen.

<details>
<summary>Step 1: editing <code>input.ini</code></summary>
<br>

1. Go to the folder:

```text
C:\Riot Games\League of Legends\Config
```

2. Open `input.ini` in a text editor.

3. In the `[GameEvents]` section, add or edit these lines:

```ini
evtShowCharacterMenu=[c],[space]
evtChampionOnly=[n],[space]
TargetChampionsOnlyAsToggle=0
```

![Example in input.ini](assets/img/03-exemplo-alcance-ataque-input-ini.png)
*Example inside input.ini*

4. Save the file and close the editor.

</details>

<details>
<summary>Step 2: editing <code>PersistedSettings.json</code></summary>
<br>

1. Go to the folder:

```text
C:\Riot Games\League of Legends\Config
```

2. Open `PersistedSettings.json` in a text editor.

3. Search for one key at a time with the editor's find box (`Ctrl+F`) and set the values like this. They sit far apart in the file, so do not expect to find the three in sequence:

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

![Example in PersistedSettings.json](assets/img/04-exemplo-alcance-ataque-persisted-settings.png)
*Example inside PersistedSettings.json*

> [!WARNING]
> Keep the JSON structure valid. Do not remove or edit other sections unless you know what you are doing.

4. Save the file and close the editor.

</details>

## Final tips

- After any configuration, close and reopen Practice Tool so the client reloads the files.
- If something goes wrong, run option `3` in the `.bat`, which puts the originals back.
- If you have no backup, delete `input.ini` and `PersistedSettings.json`. The client recreates both with default values on startup.

## References

- [YouTube: tutorial on disabling the scroll zoom](https://www.youtube.com/watch?v=db7sTv3zYAg)
- [YouTube: tutorial on always showing the attack range](https://www.youtube.com/watch?v=hTs4veZcbo8)
- [Reddit: thread on disabling the scroll zoom](https://www.reddit.com/r/leagueoflegends/comments/tvib4a/disable_zooming_inout_with_mouse_scroll_wheel/?rdt=56391)
- [Reddit: showing the attack range](https://www.reddit.com/r/ADCMains/comments/1ejlzg5/comment/lgh39ku/)

## License

MIT, thiagocajadev.
