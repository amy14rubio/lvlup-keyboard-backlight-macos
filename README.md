# LVLUP Keyboard Backlight Fix (macOS)

A small background tool that fixes LVLUP keyboards whose backlight won't
turn on when plugged into a Mac.

Once installed, press the **Screen Lock** key to toggle the backlight on
or off. It runs automatically in the background - no app to open, nothing
to run each time.

## Compatibility

Tested and confirmed working on the **LVLUP LU734**. Other LVLUP keyboards
with a "Screen Lock" key that does nothing on macOS are likely built the
same way and may also work, but haven't been confirmed. If yours is
different, see **Using a different keyboard or key** below.

## Requirements

- macOS
- Xcode Command Line Tools (free). If you don't have them:
  ```
  xcode-select --install
  ```

## Installation

1. Download this project and unzip it anywhere (Desktop, Downloads, etc).
2. Open Terminal, type `cd `, then drag the unzipped folder into the
   Terminal window and press Enter.
3. Run:
   ```
   ./install.sh
   ```
4. Go to **System Settings > Privacy & Security > Input Monitoring**, find
   this program in the list, and turn it on. (If it's not listed yet, press
   the Screen Lock key once, then check again.)
5. Press the Screen Lock key - the backlight should toggle.

That's it. It starts automatically every time you log in, and works
whenever the keyboard is plugged in.

## Uninstalling

```
./uninstall.sh
```

Then delete the folder if you want it fully removed.

## Using a different keyboard or key

The defaults already match the LVLUP LU734. If you have a different
keyboard, or want to use a different key:

1. Copy the config file: `cp kbled.env.example kbled.env`, then open it
   with `open -e kbled.env`.
2. **Find your keyboard's Vendor ID / Product ID:** with it plugged in, go
   to  **Apple menu → About This Mac → More Info… → System Report… →
   USB** (under Hardware). Click through the devices until you find your
   keyboard, then note its **Vendor ID** and **Product ID** (shown like
   `0x1234`) into `KBLED_VENDOR_ID` / `KBLED_PRODUCT_ID` in `kbled.env`.
3. **Find which key to use:** install Karabiner-Elements (free,
   karabiner-elements.pqrs.org), open Karabiner-EventViewer, and press your
   chosen key - it shows a usage page and usage number to put into
   `KBLED_TRIGGER_USAGE_PAGE` / `KBLED_TRIGGER_USAGE`. (You can remove
   Karabiner afterward; it's only needed for this lookup.)
4. **Find which LED bit controls the backlight:** run `./uninstall.sh`,
   then try `./ledctl 01`, `./ledctl 00`, `./ledctl 02`, `./ledctl 00`,
   `./ledctl 04`, `./ledctl 00`, watching the keyboard after each (`00`
   always turns it off, so you can clearly see what changed). Put whichever
   value worked into `KBLED_LED_ON_VALUE`.
5. Run `./install.sh` again to rebuild and restart with your new settings.

## Troubleshooting

**Pressing the key does nothing:** check `listener.log` in this folder. If
it mentions "not permitted", the Input Monitoring permission (step 4 above)
isn't on - enable it, then run `./uninstall.sh` followed by `./install.sh`.
If it says the keyboard wasn't found, make sure it's plugged in.

**You use Karabiner-Elements:** it grabs keyboards exclusively for its own
remapping, which blocks this tool. Run `open -e ~/.config/karabiner/karabiner.json`,
and inside your profile add (alongside anything already there):
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
Save the file - Karabiner picks up the change within a few seconds. This
only affects this one keyboard, not your other Karabiner setup.

**Stopped working after a Mac restart or macOS update:** run `./install.sh`
again. If that doesn't help, check `listener.log` and re-check the Input
Monitoring permission - macOS occasionally resets it after an update.

**Still stuck:** open an issue with what happens when you press the key,
the contents of `listener.log`, and your keyboard model.

## How it works

This talks directly to the keyboard over USB using its standard HID
protocol, sending the exact command that turns the backlight on or off. It
runs as a background service that starts automatically at login.

## Contributing

Have a different LVLUP keyboard and know whether it works? Open an issue
with your keyboard model.
