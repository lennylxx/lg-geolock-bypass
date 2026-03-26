# LG webOS TV Region Change (No Root Required)

Change the region/area code on LG webOS TVs by writing directly to NVRAM via the `lowlevelstorage` luna service, bypassing the factorymanager's built-in region lock.

**Tested on:** LG OLED77C5PUA, webOS 10.3.0, firmware 33.30.97

## Why This Exists

> **WARNING:** If your TV is currently working fine in your region, **do NOT touch the area option in the EZ-Adjust service menu**. Changing it is easy — changing it back is not. The factorymanager enforces a region lock that prevents reverting the area code, even through the same menu you used to change it. Think twice before you enter EZ-Adjust.

This project was born out of accidentally changing the area option to EU in the EZ-Adjust service menu on a US TV. The TV became geolocked to EU — different app availability, broadcast standards, and region-specific features. The EZ-Adjust menu that allowed the change refused to change it back due to a hardcoded permission check in the `factorymanager` binary.

## Background

LG TVs store a 16-bit packed "area option" value (`contiArea2All`) in NVRAM that determines the TV's region. This controls country-specific features, broadcast standards, and app availability.

The `factorymanager` service enforces an internal permission check (geolock) that prevents changing the area option back — even through the EZ-Adjust service menu that was used to set it in the first place. This geolock primarily affects the **EU region** — in testing, switching to/from other regions like China worked fine through EZ-Adjust. But once you land on EU, you're stuck. Previously, the only known solution was binary-patching the factorymanager, which requires root access.

**This method bypasses factorymanager entirely** by writing to NVRAM through the `com.webos.service.lowlevelstorage` service, which has no such restriction. No root required.

## Area Option Encoding

`contiArea2All` is a 16-bit packed field:

| Bits | Field | Description |
|------|-------|-------------|
| 0-6 | `nContinentIdx` | Continent index (7 bits) |
| 7-11 | `eLanguageCountry` | Language/country selection (5 bits) |
| 12-15 | `eHWSettingGroup` | Hardware setting group (4 bits) |

### Common Values

| Region | contiArea2All | continentIdx | languageCountry | hwSettingGroup |
|--------|--------------|--------------|-----------------|----------------|
| EU/KR | 19461 | 5 | 24 (EU) | 4 (KR) |
| US | 22282 | 10 | 14 (US) | 5 (US) |

### Language/Country Values
0=NORDIC, 1=NON NORDIC, 2=EAST EU, 3=WEST EU, 4=ETC EU, 5=AJ, 6=JA, 7=IL, 8=TW, 9=CO, 10=PA, 11=CN, 12=HK, 13=KR, **14=US**, 15=CA, 16=MX, 17=HN, 18=BR, 19=CL, 20=PE, 21=AR, 22=EC, 23=JP, **24=EU**, 25=IR, 26=PH, 27=BW, 28=CS

### HW Setting Groups
0=EU, 1=AJ JA IL, 2=TW CO, 3=CN HK, 4=KR, **5=US**, 6=SA, 7=JP

### Full Code List (KR hardware base)

These codes all use `hwSettingGroup=4 (KR)`, suitable for KR-hardware TVs:

| Region | Code | continentIdx | languageCountry | hwSettingGroup |
|--------|------|--------------|-----------------|----------------|
| AJ | 17083 | 59 | 5 (AJ) | 4 (KR) |
| AR | 19123 | 51 | 21 (AR) | 4 (KR) |
| BR | 18789 | 101 | 18 (BR) | 4 (KR) |
| CA | 18362 | 58 | 15 (CA) | 4 (KR) |
| CL | 18876 | 60 | 19 (CL) | 4 (KR) |
| CN | 17816 | 24 | 11 (CN) | 4 (KR) |
| CO | 17560 | 24 | 9 (CO) | 4 (KR) |
| EC | 19251 | 51 | 22 (EC) | 4 (KR) |
| HK | 17930 | 10 | 12 (HK) | 4 (KR) |
| HK | 17935 | 15 | 12 (HK) | 4 (KR) |
| HN | 18584 | 24 | 17 (HN) | 4 (KR) |
| HN | 18618 | 58 | 17 (HN) | 4 (KR) |
| JA | 17211 | 59 | 6 (JA) | 4 (KR) |
| JP | 19345 | 17 | 23 (JP) | 4 (KR) |
| MX | 18456 | 24 | 16 (MX) | 4 (KR) |
| PA | 17679 | 15 | 10 (PA) | 4 (KR) |
| PE | 19033 | 89 | 20 (PE) | 4 (KR) |
| PH | 15670 | 54 | 26 (PH) | 3 (CN HK) |
| TW | 17432 | 24 | 8 (TW) | 4 (KR) |
| **US** | **22282** | **10** | **14 (US)** | **5 (US)** |
| EU/KR | 19461 | 5 | 24 (EU) | 4 (KR) |

> Note: The US code (22282) uses `hwSettingGroup=5 (US)` — the proper US hardware group. All others in this list use KR hardware group.

### Calculate Your Own

Use the included `calc_area.py` utility:

```bash
# Decode an area code
python3 calc_area.py 22282
# Area option: 22282
#   continentIdx:     10
#   languageCountry:  14 (US)
#   hwSettingGroup:   5 (US)

# Encode from fields
python3 calc_area.py 10 14 5
# Area option: 22282
```

Or calculate manually:

```python
# Encode
contiArea2All = continentIdx | (languageCountry << 7) | (hwSettingGroup << 12)

# Decode
continentIdx     = contiArea2All & 0x7F
languageCountry  = (contiArea2All >> 7) & 0x1F
hwSettingGroup   = (contiArea2All >> 12) & 0xF
```

## Prerequisites

- TV and computer on the same network
- LG Developer Mode enabled on the TV

### 1. Enable Developer Mode

1. On the TV, open the **LG Content Store**
2. Search for and install **Developer Mode**
3. Open the Developer Mode app and sign in with your LG account
4. Enable **Dev Mode Status** (the TV will reboot)
5. After reboot, re-open Developer Mode and enable **Key Server**

### 2. Download the SSH Key

With Key Server enabled, run on your **computer**:

```bash
# Run on computer
wget http://<TV_IP>:9991/webos_rsa -O lg_private.key
chmod 600 lg_private.key
```

### 3. Copy Script and SSH In

Run on your **computer**:

```bash
# Run on computer — copy script to TV
scp -i lg_private.key \
    -o HostKeyAlgorithms=+ssh-rsa \
    -o PubkeyAcceptedAlgorithms=+ssh-rsa \
    -P 9922 change_region.sh prisoner@<TV_IP>:/tmp/

# Run on computer — SSH into TV
ssh -i lg_private.key \
    -o HostKeyAlgorithms=+ssh-rsa \
    -o PubkeyAcceptedAlgorithms=+ssh-rsa \
    -p 9922 prisoner@<TV_IP>
```

> **Note:** You will be prompted for a passphrase — this is shown on the **Developer Mode app** screen on your TV. It is **case-sensitive**. The `-o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa` flags are required because the TV uses the legacy `ssh-rsa` algorithm that newer SSH clients disable by default.

## Usage

Once SSH'd into the TV, run the following commands:

1. **Run the script on the TV** (via SSH):

```bash
# Run on TV — read current area option
sh /tmp/change_region.sh read

# Run on TV — change to US
sh /tmp/change_region.sh 22282

# Run on TV — verify all settings
sh /tmp/change_region.sh verify
```

2. **Reboot the TV** (via SSH):

```bash
# Run on TV
sh /tmp/change_region.sh reboot
```

3. After reboot, set country to United States in **Settings > General > System > Location** if prompted.

> **Note:** The script and pmloglib stub live in `/tmp`, which is cleared on every reboot. You'll need to copy the script again after a reboot if you want to re-run it.

## How It Works

LG webOS has three layers of region configuration:

1. **NVRAM** (hardware) — `contiArea2All` packed value, read by `factorymanager` at boot
2. **configd** (software) — priority-based config system, overridable via `setConfigs`
3. **Settings DB** — user-facing settings like country name

The `factorymanager` service has an internal ACL that blocks writing `contiArea2All` from unauthorized callers. Even the anonymous palmbus Handle (which bypasses luna-service2 bus security) gets "Permission denied."

However, `com.webos.service.lowlevelstorage` provides direct NVRAM read/write access through its `getData`/`setData` methods without any such restriction. This service is the same one that `hw-option-gen` uses to export NVRAM values to selector files at boot.

### Key Technical Details

- **Anonymous palmbus Handle**: `new pb.Handle("", true)` creates an anonymous private-bus client that bypasses luna-service2 identity checks
- **pmloglib stub**: The webos-service node module requires pmloglib, which isn't available in the prisoner shell. A stub module satisfies the dependency.
- **lowlevelstorage dbids**: Valid database groups are `system`, `factory`, `micom`, `audio`
- **Persistence**: NVRAM writes survive reboots, power cycles, and factory resets of software settings

## Shell Limitations

The prisoner shell on webOS is BusyBox-based with several restrictions:

- **No heredocs** — `cat << EOF` doesn't work. Use `echo 'content' > file` or `cat > file` with Ctrl+D instead.
- **No `luna-send`** — the binary is root-only (`-rwx------`). Use the palmbus node module via the anonymous Handle instead.
- **`luna-send-pub`** is available but limited to the public bus — most write operations are blocked.
- **`strings` command** cannot access binaries in `/usr/sbin/` (not readable by prisoner).
- **BusyBox `grep`** doesn't support `\|` alternation — use `grep -E 'a|b'` instead.
- **`/tmp` is tmpfs** — everything in `/tmp` is lost on reboot, including the script and pmloglib stub.

## Troubleshooting

### TV shows "Others" as country after reboot
This is normal on first reboot. Go to Settings > General > System > Location and manually select United States. The NVRAM value is already correct — the settings UI just needs to be re-synced once.

### SSH connection refused
- Ensure developer mode is enabled on the TV
- Use port 9922, not 22
- Add `-o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa` flags

### "Cannot find module 'pmloglib'" error
Recreate the stub — it's stored in `/tmp` which is cleared on reboot:
```bash
sh /tmp/change_region.sh setup
```

### Verify the change persisted
```bash
sh /tmp/change_region.sh verify
```

### Verify via EZ-Adjust (optional)

You can visually confirm the area code using [ColorControl](https://github.com/Maassoft/ColorControl), a free virtual service remote:

1. Open ColorControl and connect to your TV
2. Send the **IN-START** (or **EZ-Adjust**) service remote command to open the service menu
3. Navigate to **Option** > **Area Option**
4. The area code should now show **22282** (US)

## Disclaimer

This is for educational and personal use. Modifying TV firmware settings may void your warranty. Use at your own risk.

## Credits

- [epk2extract](https://github.com/openlgtv/epk2extract) by Smx for firmware extraction
- [ColorControl](https://github.com/Maassoft/ColorControl) — free virtual service remote for LG TVs, used to access EZ-Adjust
