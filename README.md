
# <img width="64" height="64" alt="AppGlyphLarge" src="https://github.com/user-attachments/assets/9dcafecf-3eac-48d5-a1d5-9281712a8a85" /> CryptoBar
<div align=center 
  
![cryptobar](https://github.com/user-attachments/assets/78cc0817-9a7d-4295-b250-ab74dda83de3)
<div align=left 

CryptoBar is a lightweight and user-friendly macOS menu bar application for tracking real-time cryptocurrency prices. Designed for simplicity and efficiency, CryptoBar lives in your menu bar, giving you a quick, at-a-glance view of your favorite cryptocurrency prices without interrupting your workflow., with open-source transparency and a focus on privacy.

## Table of Contents

- [Features](#features)
- [Installation](#installation)
  - [Recommended Method (Easy)](#recommended-method-easy)
  - [Build from Source (Advanced)](#build-from-source-advanced)
- [How to Use](#how-to-use)
- [Support the Project](#support-the-project)
- [Contributing](#contributing)
- [License](#license)
- [FAQ](#faq)
- [Acknowledgments](#acknowledgments)
- [App Interface](#app-interface)

![CryptoBar-v1.1.0](https://github.com/user-attachments/assets/f30555fb-5f0d-4e48-be0b-8f2075febc6d) <br>
[CryptoBar-v1.1.0](https://github.com/Cmalf-Labs/CryptoBar/releases/tag/1.1.0)


## Features
--------

-   **📈 Live Menu Bar Ticker**: Displays the price of your primary coin (the first in your list) directly in the menu bar.

-   **📊 Glanceable Price List**: A clean popover window showing a list of all your configured coins, complete with 24-hour performance coloring.

-   **🎨 Highly Customizable**:

    -   **Coin Selection**: Add up to 30 coins using simple symbols (`btc`, `eth`, `sol`) or specific CoinGecko IDs.

    -   **Fiat Currency**: Choose from over 15 fiat currencies (like `USD`, `EUR`, `JPY`, `GBP`, `INR`, etc.).

    -   **Refresh Rate**: Set the data refresh interval from every 10 seconds to 5 minutes.

-   **📍 Pinable Window**: Click the pin icon to keep the price list popover on top of all other windows.

-   **🚀 Launch at Login**: Set CryptoBar to start automatically when you log in to your Mac.

-   **🔄 Built-in Updates**: Includes an automatic update checker to notify you of new versions, with an option to auto-download and install.

-   **❤️ Privacy-First**: No accounts, no sign-ups, no tracking. Just a simple, anonymous API call to fetch public price data.

-   **⌨️ Quick Access**: Right-click the menu bar icon for quick access to Settings or to quit the app.

## Installation
------------

### Recommended Method (Easy)

1.  Go to the **[Latest Release](https://github.com/cmalf-labs/CryptoBar/releases/latest)** page.

2.  Download the `CryptoBar-vX.X.X.dmg` file.

3.  Open the `.dmg` file and drag **CryptoBar.app** into your **Applications** folder.

4.  Run the app from your Applications folder.


### Build from Source (Advanced)

If you prefer to build the project yourself:

1.  Clone the repository:

    Bash

    ```
    git clone https://github.com/cmalf-labs/CryptoBar.git

    ```

2.  Open the project in Xcode.

3.  Select the `CryptoBar` target and press `Cmd+B` to build.

## How to Use
----------

1.  Click the CryptoBar icon (or price) in your menu bar to open the popover.

2.  Click the **gear icon ⚙️** to open the **Settings** panel.

3.  On the **General** tab:

    -   In the **Coins Ticker** box, enter the coins you want to track, separated by commas (e.g., `btc,eth,sol,doge`). The first coin in the list will be shown in your menu bar.

    -   Select your preferred **Fiat Currency** (e.g., `USD`).

    -   Adjust the **Update Interval** slider to your liking.

    -   Toggle **Launch at login** if desired.

4.  Click **Apply**.

Your settings are saved, and the menu bar ticker will update immediately.

## Support the Project
-------------------

If you enjoy using CryptoBar, please consider supporting its development! The app has a built-in **Support** page <br> (click the **heart icon ❤️**) with several cryptocurrency donation options available.

-   **Binance Pay ID**: `96771283`

-   **Bybit Pay ID**: `117943952`

-   **Solana (SOL)**: `SoLMyRa3FGfjSD8ie6bsXK4g4q8ghSZ4E6HQzXhyNGG`

-   **EVM (ETH/BSC/etc)**: `0xbeD69b650fDdB6FBB528B0fF7a15C24DcAd87FC4`

## Contributing
------------

This project is open-source and Contributions, bug reports, and feature suggestions are very welcome!

-  Fork this repo and create a pull request.

-  Please open an [issue](https://github.com/cmalf-labs/CryptoBar/issues) to suggest enhancements or submit found bugs.

-  All levels of contributors are encouraged to participate.

## License
-------

CryptoBar is free software released under the **GNU General Public License v3.0 or later**. You can redistribute it and/or modify it under the terms of this license.

See the [LICENSE](https://www.gnu.org/licenses/gpl-3.0.en.html) file for more details.

## FAQ
---

Q: Is there any telemetry?

A: No. CryptoBar never tracks your activity or sends data to third parties.

## Acknowledgments
---------------

-   CryptoBar is developed and maintained by [Cmalf-Labs.](https://github.com/cmalf-labs)

-   Icon and UI are designed for a clean macOS experience.

-   This project is open source and made with ❤️ for the crypto & Mac,Hack community.

-   Data is sourced from [cryptobubbles.net](https://cryptobubbles.net/).
    > Price data: [cryptobubbles.net/Price](https://cryptobubbles.net/backend/data/bubbles1000.usd.json) <br>
    > Charts data: [cryptobubbles.net/Charts](https://cryptobubbles.net/backend/data/charts/day/1/USD.json)

## App Interface
--------
[CryptoBar-v1.0.0](https://github.com/Cmalf-Labs/CryptoBar/releases/tag/1.0.0)

>   **Main Interface**
<details>
  <summary>Click to view</summary>
  <img src="https://github.com/user-attachments/assets/fc88a5b2-7ee5-44f1-b4a9-df7d9d8a1c7e" alt="Main Interface">
</details>

>   **Settings**:  `General`,`Updates`,`About`
  
<details>
  <summary>Click to view</summary>
  <img src="https://github.com/user-attachments/assets/7b2cf42b-19da-441a-84eb-b49403150b0d" alt="General">
</details>
<details>
  <summary>Click to view</summary>
  <img src="https://github.com/user-attachments/assets/90ee7ac5-4e2b-4f7d-b04c-e626e2bd90a7" alt="Updates">
</details>
<details>
  <summary>Click to view</summary>
  <img src="https://github.com/user-attachments/assets/ebc6e2fd-99f3-4b83-963b-37cd947bbd4f" alt="About">
</details>

>   **Support**
  
<details>
  <summary>Click to view</summary>
  <img src="https://github.com/user-attachments/assets/e72577e3-7a34-4ae4-a1fd-bed649b3efe2" alt="Support">
</details>
