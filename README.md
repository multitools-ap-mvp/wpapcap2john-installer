# wpapcap2john-installer

A simple bootstrap script that builds `wpapcap2john` from the [John the Ripper jumbo](https://github.com/openwall/john) 
source tree and installs it to `/usr/local/bin`.

## Why this exists

`wpapcap2john` converts WPA/WPA2 handshake captures (`.pcap`/`.cap`) directly into a crackable hash format for John the Ripper, in a single step — no need to pre-filter with `aircrack-ng` or convert through `.hccap` first.
It also tends to pick up handshakes that `aircrack-ng` misses.

The problem: it's **not a released binary**.
It only exists inside the John jumbo source tree, isn't packaged by most distros, and there's no standalone installer
You have to clone and compile the whole John the Ripper jumbo project just to get one tool out of it.
This script automates that.

It's also a required dependency for [Sparrow-wifi](https://github.com/ghostop14/sparrow-wifi) —
Sparrow's WPA-capture workflow expects `wpapcap2john` to be on your `PATH` (in `/usr/bin` or `/usr/local/bin`), and its own docs don't tell you how to get it there.

## What the script does

1. Installs build dependencies (`build-essential`, `libssl-dev`, `zlib1g-dev`, `libgmp-dev`, `libpcap-dev`, etc.)
2. Clones the John the Ripper jumbo repo (`bleeding-jumbo`) into `/opt/john-build`
3. Runs `./configure` and `make` to compile the full jumbo toolset
4. Verifies `wpapcap2john` was actually produced
5. Symlinks `wpapcap2john`, `john`, and a few other commonly-used `*2john` tools into `/usr/local/bin`
6. Runs a quick sanity check (`wpapcap2john -h`)

## Requirements

- Debian/Ubuntu/Kali-based system (uses `apt`)
- `sudo`/root access
- Internet connection (for `apt` and cloning the repo)

## Usage

```bash
git clone https://github.com/multitools-ap-mvp/wpapcap2john-installer.git
cd wpapcap2john-installer
chmod +x setup_wpapcap2john.sh
sudo ./setup_wpapcap2john.sh
```

Once it finishes:

```bash
wpapcap2john your_capture.pcap > hashes.txt
john hashes.txt --wordlist=your_wordlist.txt
```

//

## Notes

- `BUILD_DIR` defaults to `/opt/john-build`; override it if you want the source elsewhere:
  ```bash
  BUILD_DIR=/some/path sudo -E ./setup_wpapcap2john.sh
  ```
  ———
  
- The script uses symlinks rather than copies
- so `wpapcap2john` stays linked to its build directory (it expects some files to be nearby).
- Tested against the current `bleeding-jumbo` branch as of mid-2026. Upstream changes could occasionally break the build — open an issue if `make` fails and paste the error.

## Legal

`wpapcap2john` and John the Ripper are password-auditing tools. Only use them against networks and captures you own or are explicitly authorized to test. This installer just automates a build; it doesn't grant any authorization on its own.

## License

MIT — see [LICENSE](LICENSE). John the Ripper itself is licensed separately (mostly GPLv2); this repo only contains the installer script.

