# PakTicker

![Platform](https://img.shields.io/badge/platform-Windows-blue?logo=windows)
![PowerShell](https://img.shields.io/badge/PowerShell-5.1+-blue?logo=powershell)
![Binance](https://img.shields.io/badge/API-Binance-yellow?logo=binance)
![License](https://img.shields.io/badge/license-MIT-green)
![Open Source](https://img.shields.io/badge/open%20source-%E2%9D%A4-red)

A lightweight always-on-top desktop ticker for crypto prices and Binance P2P USDT/PKR rates. Sits in the top-right corner, stays out of Alt+Tab and Win+Tab.

## Preview

<div align="center">
  <img src="assets/preview.png" width="280"/>
</div>

## What it shows

**Crypto prices** (via Binance spot API)

- BTC, CFX, GOLD (PAXG proxy) — price + 24h % change
- Add any Binance spot symbol at runtime via the `+ add coin` button
- All coins except GOLD can be removed with the `×` button

**P2P Binance** (USDT/PKR, merchants only)

| Row  | Color | Meaning                                            |
| ---- | ----- | -------------------------------------------------- |
| B-Hi | Green | Best rate to **buy** USDT — high-volume threshold  |
| B-Lo | Green | Best rate to **buy** USDT — low-volume threshold   |
| S-Hi | Red   | Best rate to **sell** USDT — high-volume threshold |
| S-Lo | Red   | Best rate to **sell** USDT — low-volume threshold  |

Each P2P row shows: `trader name | rate | min-max limit`  
Hover over a row for full tooltip: orders, completion %, available USDT, payment methods.

## Installation

1. **Download** — clone or download this repo to any folder on your PC.
2. **Run** — double-click `start.vbs`. No installer needed.
3. **Startup** — to launch the gadget at every login, place a shortcut to `start.vbs` in your startup folder:
   - Press `Win + R`, type `shell:startup`, press **Enter**
   - Copy a shortcut to `start.vbs` into that folder

To undo, see [Removing startup entry](#removing-startup-entry).

## P2P rates explained

Binance P2P is a peer-to-peer marketplace where individual traders post buy/sell ads for USDT priced in PKR. The gadget queries **merchant-verified traders only** and picks the best available rate for each row.

### Hi / Lo thresholds

The Hi and Lo rows each query P2P with a different transaction amount. This matters because large-volume traders often post different rates than small-volume ones:

- **Hi threshold** (default 100,000 PKR) — finds the best rate among traders whose ad minimum is within reach of that amount. Useful if you're moving a larger sum.
- **Lo threshold** (default 1,000 PKR) — same query at a lower amount. Shows what's available for small trades, which is typically a wider pool of traders.

You can adjust both thresholds directly from the gadget — click `−`/`+` to step in increments, or **click the value itself** to type any number (supports `k` suffix, e.g. `50k`). Changes are saved to `config.json` immediately.

### How traders are ranked

For each query the API returns up to 20 ads. The gadget then filters out any ad where the trader does not have enough USDT available to actually fill the requested transaction amount, then picks **rank #1** from what remains. In practice this means the displayed trader:

- Is a verified merchant
- Has live inventory sufficient to cover at least their own minimum order
- Is the best-priced offer in that tier at the moment of the last refresh

Hovering over any P2P row shows the full detail: monthly order count, completion rate, available USDT surplus, and accepted payment methods.

## Controls

| Action                           | Result                                    |
| -------------------------------- | ----------------------------------------- |
| Right-click                      | Confirm close overlay                     |
| Esc                              | Dismiss overlay / close                   |
| Click `+ add coin`               | Add any Binance symbol (e.g. `ETHUSDT`)   |
| Click `×` on a row               | Remove that coin                          |
| Click `−` / `+` next to Hi or Lo | Step threshold by 10k / 500 PKR           |
| Click the threshold value        | Type a custom value (supports `k` suffix) |

## Adding coins

1. Click `+ add coin` at the bottom of the coins section
2. Type a valid Binance spot symbol (e.g. `SOLUSDT`, `BNBUSDT`)
3. Press **Enter** or click **Add** — validated live against Binance API
4. Saved automatically to `config.json`

Coins are loaded from `config.json` on startup. If the file is missing, defaults (BTC, CFX, GOLD) are used.

## Removing startup entry

To stop the gadget from launching at login:

- Press `Win + R`, type `shell:startup`, press **Enter**
- Delete the `start.vbs` shortcut from that folder

## Refresh rates

| Data          | Interval                       |
| ------------- | ------------------------------ |
| Crypto prices | Every 5 seconds                |
| P2P rates     | Every 10 seconds (4 API calls) |

## License

MIT © 2026

## Customization

- **`$pollSeconds`** — crypto price refresh interval (default 5 s)
- **P2P thresholds** — adjustable live from the UI; persisted in `config.json`
- **`$margin`** — gap from screen edge in pixels
