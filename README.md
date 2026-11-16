# Voicehau

A client-side mod for Mordhau that lets you fire voicelines whenever you want : 
the current line is cut off and the new one starts right away. Other players hear it too.

There is no code injection and the game executable is not modified.

## Install

1. Install the [Clientside Mod Autoloader](https://mordhau.mod.io/clientside-mod-autoloader)
2. Go to the [**Releases**](../../releases/latest) page and download `Voicehau-vX.Y.zip`.
   Do **not** use the green "Code" button: the source download doesn't include the mod file.
3. Extract the zip anywhere.
4. Close Mordhau, then double-click **`Install Voicehau.bat`**.
   If Windows shows a security warning, click "More info" then "Run anyway".
5. Start Mordhau. Voicehau should appear in the autoloader mod list, and the chat shows
   a "loaded" message once you are in a match.

To remove it, double-click **`Uninstall Voicehau.bat`**.

## Controls

1. Play any voiceline from Mordhau's own voice menus. Voicehau remembers it.
2. Press **Numpad 1 to 9** to pick a variation (1 = first variation). The chat confirms it.
3. Spam **Numpad 0** to replay that voiceline with that variation. Each press cuts off the
   previous one.

| Key | Action |
|---|---|
| Numpad 1-9 | Pick variation 1 to 9 |
| **Numpad 0** | Play the last voiceline with the picked variation |

## Notes

- **Voice spam can get you banned or kicked by admins/devs**. Use it with taste.
- Voicelines don't all have the same number of variations. If the picked one doesn't
  exist, the chat says so and nothing plays.

## What the installer does

- Finds Mordhau: Steam libraries first, then the default Epic location, otherwise it asks
  you for the folder.
- Warns you if the autoloader is missing.
- Copies `VoicehauWindowsClient.pak` into `Mordhau\Content\CustomPaks`.
- Adds `ClientMods=/Voicehau/BP_VoicehauClient.BP_VoicehauClient_C` to the autoloader
  section of `%LOCALAPPDATA%\Mordhau\Saved\Config\WindowsClient\Game.ini`. Other mods are
  left untouched, and a timestamped backup of `Game.ini` is made before any change.

Advanced options, from PowerShell: `-DryRun`, `-MordhauPath`, `-GameIni`, `-PakSource`.

## Credits

- Install mechanism inspired by [LuteBot3](https://github.com/Dimencia/LuteBot3).
- [Clientside Mod Autoloader](https://mordhau.mod.io/clientside-mod-autoloader) by cswic
  (not redistributed here).

Mordhau is a trademark of Triternion. This project is not affiliated with or endorsed by Triternion.

## License

[MIT](LICENSE)
