# <img width="64" height="64" alt="CryptoBar icon" src="https://github.com/user-attachments/assets/9dcafecf-3eac-48d5-a1d5-9281712a8a85" /> CryptoBar

[![GitHub release](https://img.shields.io/github/v/release/Cmalf-Labs/CryptoBar)](https://github.com/Cmalf-Labs/CryptoBar/releases/latest)
[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Platform: macOS 13.5+](https://img.shields.io/badge/macOS-13.5%2B-lightgrey.svg)](https://github.com/Cmalf-Labs/CryptoBar/releases/latest)
[![Swift 5](https://img.shields.io/badge/Swift-5-orange.svg)](https://swift.org)

**CryptoBar is a lightweight, privacy-first macOS menu bar app for tracking cryptocurrency prices in real time.** It lives in your menu bar and shows your favorite coins at a glance — no account, no sign-up, no tracking, no interruption to your workflow.

<img width="1920" height="1079" alt="cryptobar" src="https://github.com/user-attachments/assets/201efcbf-709d-4483-9b13-c0d04568212e" />

## Contents

- [Features](#features)
- [Installation](#installation)
- [How to Use](#how-to-use)
- [Support the Project](#support-the-project)
- [Contributing](#contributing)
- [FAQ](#faq)
- [Acknowledgments](#acknowledgments)
- [License](#license)

## Features

- **📈 Live menu bar ticker** — the price of your first coin is always visible in the menu bar.
- **📊 Glanceable price list** — a clean popover with all your coins, colored by 24-hour performance.
- **🔍 Search** — instantly filter the price list by ticker or coin name.
- **👀 Watcher / All Coins / Categories** — switch between your watchlist (up to 100 coins), a browsable list of the top 1,200 coins by market rank, and 12 curated categories (Layer 1, DeFi, Meme, AI, RWA, Gaming, Smart Contract Platform, Stablecoins, Tokenized Assets, DePIN, NFT, Infrastructure). Tap **+** on any coin in All Coins or Categories to add it to your watchlist, or tap **−** on any coin in Watcher mode to remove it.
- **💡 Coin suggestions** — start typing in Settings and get up to 6 matching coins, ordered by rank.
- **🔔 Price alerts** — one-shot alerts per coin. Get a macOS notification the moment a price crosses your target, then the alert clears itself.
- **📉 Charts & converter** — per-coin charts (hour, day, week, month, year) with a built-in fiat converter.
- **↕️ Drag & drop ordering** — reorder your coins in Settings; the first coin drives the menu bar ticker.
- **🎨 Highly customizable**
  - **Coins:** track up to 100 coins by symbol (`btc`, `eth`, `sol`) or CoinGecko ID.
  - **Fiat:** 14 currencies — USD, EUR, GBP, BRL, CAD, AUD, PLN, INR, RUB, CHF, ZAR, TRY, JPY, KRW.
  - **Refresh rate:** every 10 seconds to 5 minutes (default: 30 seconds).
- **📌 Pinnable window** — pin the popover so it stays on top of other windows.
- **🚀 Launch at login** — start CryptoBar automatically when you sign in.
- **🔄 Built-in updates** — automatic update checks with auto-download and install on by default for new installs (existing users who turned it off keep their setting).
- **❤️ Privacy-first** — no accounts, no sign-ups, no telemetry. The app only makes anonymous requests for public price data.
- **⌨️ Quick access** — right-click the menu bar icon for Settings or to quit.

## Installation

### Recommended — download the app

1. Go to the [**Latest Release**](https://github.com/Cmalf-Labs/CryptoBar/releases/latest) page.
2. Download the `CryptoBar-1.1.1.dmg` file.
3. Open the `.dmg` and drag **CryptoBar.app** into your **Applications** folder.
4. Launch CryptoBar from Applications.

Requires macOS 13.5 or later.

### Build from source

1. Clone the repository:

   ```bash
   git clone https://github.com/Cmalf-Labs/CryptoBar.git
   ```

2. Open `CryptoBar.xcodeproj` in Xcode 26 or later.
3. Select the `CryptoBar` target and press `Cmd+B` to build (or `Cmd+R` to run).

## How to Use

1. Click the CryptoBar icon (or price) in your menu bar to open the popover.
2. Click the **gear icon ⚙️** to open **Settings**.
3. Under **General**:
   - In the **Coins Ticker** box, enter the coins you want to track, separated by commas (e.g. `btc,eth,sol,doge`). The first coin is shown in the menu bar.
   - Pick your preferred **fiat currency** (e.g. `USD`).
   - Adjust the **update interval** slider to your liking.
   - Toggle **Launch at login** if you want CryptoBar to start with your Mac.
4. Click **Apply**. Your settings are saved and the menu bar ticker updates immediately.

**Tips**

- Use the **search field** at the top of the price list to find any coin quickly.
- Switch to **All Coins** to browse the top 1,200 coins, then tap **+** to add one to your watchlist — or tap **−** in Watcher mode to remove one.
- Open **Categories** to browse by theme (e.g. Meme, DeFi, AI); category data refreshes at most once a day, with its own **Refresh data** button in the Categories header, separate from the price refresh button.
- In a coin's **Charts** window, set a **price alert** below the converter — you'll be notified once when the target is crossed.
- Drag coin chips in Settings to reorder your list; the first coin becomes the menu bar ticker.

## Support the Project

If you enjoy CryptoBar, consider supporting its development. The app has a built-in **Support** page (click the **heart icon ❤️**) with these donation options:

- **Binance Pay ID:** `96771283`
- **Bybit Pay ID:** `117943952`
- **Solana (SOL):** `CMALF2xvsZPE6ygTnQgj25pCjdDryewYJWXpRw4fqfM3`
- **EVM (ETH / BSC / etc.):** `0xbeD69b650fDdB6FBB528B0fF7a15C24DcAd87FC4`

## Contributing

CryptoBar is open source — contributions, bug reports, and feature suggestions are very welcome.

- Fork the repo and open a pull request.
- [Open an issue](https://github.com/Cmalf-Labs/CryptoBar/issues) to report a bug or suggest an enhancement.
- Contributors of all levels are encouraged to participate.

## FAQ

**Is there any telemetry?**

No. CryptoBar never tracks your activity or sends data to third parties.

**Where does the price data come from?**

Price data is sourced from [cryptobubbles.net](https://cryptobubbles.net/):

- Prices: [`bubbles1000.usd.json`](https://cryptobubbles.net/backend/data/bubbles1000.usd.json)
- Charts: [`charts/day/1/USD.json`](https://cryptobubbles.net/backend/data/charts/day/1/USD.json)
- Categories: [`metadata.json`](https://cryptobubbles.net/backend/data/metadata.json)

## Acknowledgments

- CryptoBar is developed and maintained by [Cmalf-Labs](https://github.com/Cmalf-Labs).
- Icon and UI are designed for a clean macOS experience.
- Made with ❤️ for the crypto & Mac community.

## License

CryptoBar is free software released under the **GNU General Public License v3.0 or later**. You can redistribute it and/or modify it under the terms of this license. See the [LICENSE](https://www.gnu.org/licenses/gpl-3.0.en.html) file for details.
