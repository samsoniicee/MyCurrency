# MyCurrency

A minimal macOS menu bar currency converter for **EUR, USD, and AED** — live rates, instant conversion in all directions.

![macOS](https://img.shields.io/badge/macOS-14%2B-black) ![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- Lives in the **menu bar** — one click to open, click away to close
- Type in any field → all others update instantly
- **Live EUR/USD rate** fetched from [Frankfurter API](https://www.frankfurter.app/) (ECB data)
- **AED** uses the official fixed peg: 1 USD = 3.6725 AED (UAE Central Bank, unchanged since 1997)
- Thousands separator formatting (`1,000,000.00`) with adaptive font size for large numbers
- Click into a field → existing value auto-selected, just type to replace
- Refresh button to pull the latest EUR rate
- Single instance enforcement — no duplicate menu bar icons

## Requirements

- macOS 14 (Sonoma) or later
- Xcode 15+ (to build from source)

## Build & Install

```bash
# Build Release
xcodebuild \
  -project MyCurrency.xcodeproj \
  -scheme MyCurrency \
  -configuration Release \
  -derivedDataPath /tmp/MyCurrency-build \
  build

# Install to /Applications
cp -R /tmp/MyCurrency-build/Build/Products/Release/MyCurrency.app /Applications/
```

Then launch via Spotlight (`⌘Space` → "MyCurrency") or open `/Applications/MyCurrency.app`.

To start automatically at login: **System Settings → General → Login Items → add MyCurrency**.

## Architecture

| File | Role |
|---|---|
| `MyCurrencyApp.swift` | App entry point, `MenuBarExtra` scene, single-instance guard |
| `ContentView.swift` | SwiftUI layout — header, 3 currency rows, footer |
| `CurrencyTextField.swift` | `NSViewRepresentable` wrapping a custom `NSTextField` subclass; handles live input, select-all on focus, adaptive font, format-on-blur |
| `CurrencyViewModel.swift` | `ObservableObject` — rate fetching, conversion logic, `@Published` text fields with `didSet`-driven live conversion |

## How conversion works

`@Published var eur/usd/aed` each have a `didSet` observer. When any binding is written to by the user typing, `compute()` runs synchronously — no SwiftUI `onChange` timing gaps. A `busy: Bool` flag on the reference type prevents the other fields' `didSet` from re-triggering while values are being written.

## Rate sources

| Pair | Source |
|---|---|
| EUR/USD | [api.frankfurter.app](https://api.frankfurter.app/latest?from=USD&to=EUR) — ECB reference rate, updated daily |
| AED/USD | Hardcoded `3.6725` — official UAE Central Bank peg |

## Made by

**niicee** — built with Claude
