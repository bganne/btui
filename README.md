# btui

A small terminal UI (whiptail) on top of `bluetoothctl` for pairing and connecting
headsets, speakers and other Bluetooth devices.

- List paired devices (connected first, with type and battery), connect / disconnect / forget
- Scan for new devices, sorted by signal strength, and pair + trust + connect in one step
- "Just works" pairing (devices that need a PIN or passkey entry are not supported yet)
- Turn the adapter on/off, unblocking rfkill if needed

## Requirements

`bluez`, `whiptail`.

```sh
sudo apt install bluez whiptail
```

## Usage

```sh
./btui
```

| Variable      | Default | Meaning                                  |
|---------------|---------|------------------------------------------|
| `SCAN_SECS`   | `10`    | Length of the initial scan, in seconds   |
| `NEWT_COLORS` | —       | Optional whiptail colour theme           |

## Tests

```sh
./test.sh
```

Runs `shellcheck` (required), `bash -n`, and unit tests of the parsing/listing functions against a stubbed
`bluetoothctl`. No Bluetooth hardware needed.
