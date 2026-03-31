# LG webOS TV Region Change (No Root Required)

Change the region/area code on LG webOS TVs by writing directly to NVRAM via the `lowlevelstorage` luna service, bypassing the factorymanager's built-in region lock.

**Tested on:** LG OLED77C5PUA, webOS 10.3.0, firmware 33.30.97

## Why This Exists

> **WARNING:** If your TV is currently working fine in your region, **do NOT touch the area option in the EZ-Adjust service menu**. Changing it is easy — changing it back is not.

This project was born out of accidentally changing the area option to EU in the EZ-Adjust service menu on a US TV. The `factorymanager` binary enforces a region lock (geolock) that prevents reverting the area code — even through the same EZ-Adjust menu that was used to change it. This primarily affects the **EU region** — switching to/from other regions like China works fine, but once you land on EU, you're stuck. The TV became geolocked with different app availability, broadcast standards, and region-specific features.

Previously, the only known solution was binary-patching the factorymanager, which requires root access. **This method bypasses factorymanager entirely** by writing to NVRAM through the `com.webos.service.lowlevelstorage` service, which has no such restriction. No root required.

## Usage

### Prerequisites

- TV and computer on the same network
- LG Developer Mode enabled on the TV

### 1. Enable Developer Mode

1. On the TV, open the **LG Content Store**
2. Search for and install **Developer Mode**
3. Open the Developer Mode app and sign in with your LG account
4. Enable **Dev Mode Status** (the TV will reboot)
5. After reboot, re-open Developer Mode and enable **Key Server**

> **If your TV is stuck in EU:** The LG Content Store requires a region-matching LG account to download apps. You may need to temporarily set your TV's country to a specific EU country (e.g., United Kingdom) in Settings, agree to the user agreement, then register a new LG account with a new email address to download the Developer Mode app. Once installed, you can sign into the Developer Mode app with either your new EU or original US LG account.

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

### 4. Change Region

Once SSH'd into the TV:

```bash
# Run on TV — read current area option
sh /tmp/change_region.sh read

# Run on TV — change to US
sh /tmp/change_region.sh 22282

# Run on TV — verify all settings
sh /tmp/change_region.sh verify
```

Reboot the TV:

```bash
# Run on TV
sh /tmp/change_region.sh reboot
```

After reboot, select your country (United States) in **Settings > General > System > Location** if prompted.

> **Note:** The script and pmloglib stub live in `/tmp`, which is cleared on every reboot. You'll need to copy the script again after a reboot if you want to re-run it.

### Verify via EZ-Adjust (optional)

You can visually confirm the area code using [ColorControl](https://github.com/Maassoft/ColorControl), a free virtual service remote:

1. Open ColorControl and connect to your TV
2. Send the **IN-START** (or **EZ-Adjust**) service remote command to open the service menu
3. Navigate to **Option** > **Area Option**
4. The area code should now show **22282** (US)

### Changing to Other Regions

To change to a different region, replace the area code. For example, to change to China:

```bash
# Run on TV — change to China
sh /tmp/change_region.sh 13741
```

See the [Known Area Codes](#known-area-codes) table for other region codes.

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

## Known Area Codes

Some regions have multiple codes with different hardware setting groups. If unsure, pick the one that matches your TV's original region (e.g., a US-bought TV should use hwSettingGroup 5/US).

| Name | Region | Code | continentIdx | languageCountry | hwSettingGroup |
|------|--------|------|--------------|-----------------|----------------|
| Argentina | AR | 19123 | 51 | 21 (AR) | 4 (KR) |
| Brazil | BR | 18789 | 101 | 18 (BR) | 4 (KR) |
| Canada | CA | 18362 | 58 | 15 (CA) | 4 (KR) |
| Chile | CL | 18876 | 60 | 19 (CL) | 4 (KR) |
| China | CN | 13741 | 45 | 11 (CN) | 3 (CN HK) |
| China | CN | 17816 | 24 | 11 (CN) | 4 (KR) |
| Colombia | CO | 17560 | 24 | 9 (CO) | 4 (KR) |
| Ecuador | EC | 19251 | 51 | 22 (EC) | 4 (KR) |
| European Union (EU hw) | EU | 3122 | 50 | 24 (EU) | 0 (EU) |
| **European Union (KR hw)** | **EU** | **19461** | **5** | **24 (EU)** | **4 (KR)** |
| Honduras | HN | 18584 | 24 | 17 (HN) | 4 (KR) |
| Honduras | HN | 18618 | 58 | 17 (HN) | 4 (KR) |
| Hong Kong | HK | 13869 | 45 | 12 (HK) | 3 (CN HK) |
| Hong Kong | HK | 17930 | 10 | 12 (HK) | 4 (KR) |
| Hong Kong | HK | 17935 | 15 | 12 (HK) | 4 (KR) |
| Japan | JP | 19345 | 17 | 23 (JP) | 4 (KR) |
| Mexico | MX | 18456 | 24 | 16 (MX) | 4 (KR) |
| Middle East Asia & Africa | JA | 17211 | 59 | 6 (JA) | 4 (KR) |
| Panama | PA | 17679 | 15 | 10 (PA) | 4 (KR) |
| Peru | PE | 19033 | 89 | 20 (PE) | 4 (KR) |
| Philippines | PH | 15670 | 54 | 26 (PH) | 3 (CN HK) |
| Singapore | AJ | 4837 | 101 | 5 (AJ) | 1 (AJ JA IL) |
| Taiwan | TW | 17432 | 24 | 8 (TW) | 4 (KR) |
| **United States** | **US** | **22282** | **10** | **14 (US)** | **5 (US)** |

> Note: The US code (22282) uses `hwSettingGroup=5 (US)` — the proper US hardware group. Most others in this list use KR hardware group.

## Area Option Encoding

LG TVs store a 16-bit packed "area option" value (`contiArea2All`) in NVRAM that determines the TV's region. This controls country-specific features, broadcast standards, and app availability.

| Bits | Field | Description |
|------|-------|-------------|
| 0-6 | `nContinentIdx` | Continent index (7 bits) |
| 7-11 | `eLanguageCountry` | Language/country selection (5 bits) |
| 12-15 | `eHWSettingGroup` | Hardware setting group (4 bits) |

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

See [Language/Country Values](#languagecountry-values-elanguagecountry) and [HW Setting Groups](#hw-setting-groups-ehwsettinggroup) below for valid field values.

Or calculate manually:

```python
# Encode
contiArea2All = continentIdx | (languageCountry << 7) | (hwSettingGroup << 12)

# Decode
continentIdx     = contiArea2All & 0x7F
languageCountry  = (contiArea2All >> 7) & 0x1F
hwSettingGroup   = (contiArea2All >> 12) & 0xF
```

### Language/Country Values (`eLanguageCountry`)

| Value | Code | Name | Config Group | Default Country | Countries (Settings UI) |
|-------|------|------|--------------|-----------------|------------------------|
| 0 | NORDIC | Nordic | EU | — | SWE (Sweden), DNK (Denmark), NOR (Norway), FIN (Finland) |
| 1 | NON NORDIC | Non-Nordic | EU | — | ALB (Albania), AUT (Austria), BLR (Belarus), BEL (Belgium), BIH (Bosnia), BGR (Bulgaria), HRV (Croatia), CZE (Czech), EST (Estonia), FRA (France), DEU (Germany), GRC (Greece), HUN (Hungary), IRL (Ireland), ITA (Italy), KAZ (Kazakhstan), LVA (Latvia), LTU (Lithuania), LUX (Luxembourg), NLD (Netherlands), POL (Poland), PRT (Portugal), ROU (Romania), RUS (Russia), SRB (Serbia), SVK (Slovakia), SVN (Slovenia), ESP (Spain), CHE (Switzerland), TUR (Türkiye), GBR (UK), UKR (Ukraine) |
| 2 | EAST EU | East EU | EU | — | ALB (Albania), BIH (Bosnia), BGR (Bulgaria), HRV (Croatia), CZE (Czech), EST (Estonia), HUN (Hungary), LVA (Latvia), LTU (Lithuania), POL (Poland), ROU (Romania), SRB (Serbia), SVK (Slovakia) |
| 3 | WEST EU | West EU | EU | GBR (UK) | AUT (Austria), BEL (Belgium), FRA (France), DEU (Germany), MKD (Macedonia), GRC (Greece), IRL (Ireland), ITA (Italy), LUX (Luxembourg), NLD (Netherlands), PRT (Portugal), SVN (Slovenia), ESP (Spain), CHE (Switzerland), GBR (UK) |
| 4 | ETC EU | Etc EU | EU | — | BLR (Belarus), KAZ (Kazakhstan), MNG (Mongolia), RUS (Russia), TUR (Türkiye), UKR (Ukraine) |
| 5 | AJ | Asia | AJ | AUS (Australia) | AUS (Australia), KHM (Cambodia), IND (India), IDN (Indonesia), MYS (Malaysia), MMR (Myanmar), NZL (New Zealand), PHL (Philippines), SGP (Singapore), LKA (Sri Lanka), THA (Thailand), VNM (Vietnam) |
| 6 | JA | Middle East Asia & Africa | JA | ZAF (South Africa) | BHR (Bahrain), CMR (Cameroon), DZA (Algeria), GHA (Ghana), IRQ (Iraq), JOR (Jordan), KEN (Kenya), KWT (Kuwait), LBN (Lebanon), LBY (Libya), MWI (Malawi), MUS (Mauritius), MAR (Morocco), NAM (Namibia), NGA (Nigeria), OMN (Oman), QAT (Qatar), SAU (Saudi Arabia), ZAF (South Africa), TUN (Tunisia), UGA (Uganda), ARE (UAE), YEM (Yemen), ZMB (Zambia), ZWE (Zimbabwe) |
| 7 | IL | Israel | IL | ISR (Israel) | ISR (Israel) |
| 8 | TW | Taiwan | TW | TWN (Taiwan) | TWN (Taiwan) |
| 9 | CO | Colombia | TW | COL (Colombia) | COL (Colombia) |
| 10 | PA | Panama | BR | HND (Honduras) | HND (Honduras), MEX (Mexico), PAN (Panama) |
| 11 | CN | China | CN | CHN (China) | CHN (China) |
| 12 | HK | Hong Kong | HK | HKG (Hong Kong) | HKG (Hong Kong) |
| 13 | KR | Korea | KR | KOR (South Korea) | KOR (South Korea) |
| **14** | **US** | **United States** | **US** | **USA (United States)** | **USA (United States)** |
| 15 | CA | Canada | US | CAN (Canada) | CAN (Canada) |
| 16 | MX | Mexico | US | MEX (Mexico) | MEX (Mexico) |
| 17 | HN | Honduras | BR | HND (Honduras) | HND (Honduras) |
| 18 | BR | Brazil/South America | BR | BRA (Brazil) | BRA (Brazil) |
| 19 | CL | Chile | BR | CHL (Chile) | CHL (Chile) |
| 20 | PE | Peru | BR | PER (Peru) | PER (Peru) |
| 21 | AR | Argentina | BR | ARG (Argentina) | ARG (Argentina) |
| 22 | EC | Ecuador | BR | ECU (Ecuador) | ECU (Ecuador) |
| 23 | JP | Japan | JP | JPN (Japan) | JPN (Japan) |
| **24** | **EU** | **EU** | **EU** | **GBR (UK)** | **ALB (Albania), AUT (Austria), BEL (Belgium), BIH (Bosnia), BGR (Bulgaria), HRV (Croatia), CZE (Czech), DNK (Denmark), EST (Estonia), FIN (Finland), FRA (France), DEU (Germany), GRC (Greece), HUN (Hungary), ISL (Iceland), IRL (Ireland), ITA (Italy), LVA (Latvia), LTU (Lithuania), LUX (Luxembourg), MKD (Macedonia), NLD (Netherlands), NOR (Norway), POL (Poland), PRT (Portugal), ROU (Romania), SRB (Serbia), SVK (Slovakia), SVN (Slovenia), ESP (Spain), SWE (Sweden), CHE (Switzerland), TUR (Türkiye), GBR (UK)** |
| 25 | IR | Iran | JA | IRN (Iran) | IRN (Iran) |
| 26 | PH | Philippines | BR | PHL (Philippines) | PHL (Philippines) |
| 27 | BW | Botswana | BR | BWA (Botswana) | BWA (Botswana) |
| 28 | CS | CIS | CS | RUS (Russia) | BLR (Belarus), KAZ (Kazakhstan), UZB (Uzbekistan), MNG (Mongolia), RUS (Russia), UKR (Ukraine) |

### HW Setting Groups (`eHWSettingGroup`)

| Value | Code | Name |
|-------|------|------|
| 0 | EU | Europe |
| 1 | AJ JA IL | Asia / Middle East Asia & Africa / Israel |
| 2 | TW CO | Taiwan / Colombia |
| 3 | CN HK | China / Hong Kong |
| 4 | KR | South Korea |
| **5** | **US** | **United States** |
| 6 | SA | South America |
| 7 | JP | Japan |

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

## Disclaimer

This is for educational and personal use. Modifying TV firmware settings may void your warranty. The author is not responsible for any damages to your TV. Use at your own risk.

## Credits

- [epk2extract](https://github.com/openlgtv/epk2extract) by Smx for firmware extraction
- [ColorControl](https://github.com/Maassoft/ColorControl) — free virtual service remote for LG TVs, used to access EZ-Adjust
