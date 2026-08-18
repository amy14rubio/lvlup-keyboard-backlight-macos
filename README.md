# LVLUP Keyboard Backlight Fix (macOS)

Some LVLUP keyboards can't turn their backlight on when plugged into a Mac.
This tool fixes that by letting you toggle the backlight using a key on the
keyboard itself (by default, the key labeled "Screen Lock"). Once installed,
it runs quietly in the background and just works - no app to open, nothing
to remember.

## Requirements

- macOS
- Xcode Command Line Tools (free). If you don't already have them, run this
  in Terminal:
  ```
  xcode-select --install
  ```

## Installation

1. Download this folder to your computer (anywhere is fine - Desktop,
   Downloads, wherever).
2. Open Terminal and navigate into the folder:
   ```
   cd path/to/this-folder
   ```
3. Run the installer:
   ```
   ./install.sh
   ```
4. macOS will require one manual step: go to **System Settings > Privacy &
   Security > Input Monitoring**, find this program in the list, and turn it
   on. (If it's not in the list yet, press your keyboard's trigger key once,
   then check again.)
5. Press the trigger key on your keyboard. The backlight should turn on/off.

Once set up, it starts automatically every time you log in and works
whenever the keyboard is plugged in - you don't need to run anything again.

## Uninstalling

```
./uninstall.sh
```

This stops the background service. You can then delete the folder if you
want to remove it completely.

## Troubleshooting

**Pressing the key does nothing:**
Double check the Input Monitoring permission from step 4 above. You can also
check `listener.log` in this folder for error messages.

**You use Karabiner-Elements:**
Karabiner may be grabbing your keyboard for its own remapping, which blocks
this tool from reaching it. Open `~/.config/karabiner/karabiner.json` and add
the following inside your profile (alongside anything already there):
```json
"devices": [
    {
        "identifiers": {
            "is_keyboard": true,
            "vendor_id": 49396,
            "product_id": 4341
        },
        "ignore": true
    }
]
```

**You have a different keyboard, or want to use a different key:**
Open `kbled.env.example`, copy it to `kbled.env`, and follow the comments
inside it - it walks through finding your keyboard's ID numbers and the key
you want to use. Re-run `./install.sh` after editing.
