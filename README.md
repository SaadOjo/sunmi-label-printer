# SUNMI Label Printer / OJO Print Studio

This repository contains a macOS label/receipt printer workspace for SUNMI printers.

## What is included

- `OJOPrintStudioSwift/` — the current SwiftUI app, **OJO Print Studio Swift**.
  - Connects to SUNMI printers over LAN/IP using the SUNMI macOS SDK bridge.
  - Includes a dot-accurate label designer.
  - Renders labels to a 1-bit bitmap preview and prints TSPL `BITMAP` commands.
  - Persists designer settings and elements between app launches.
- `MacOSApp/` — the original Objective-C SUNMI SDK demo, kept as a reference and SDK source.
- `MacOSApp/SunmiPrinterMacOS.framework` — SUNMI macOS framework used by the SwiftUI app.
- `cli/` — experimental JSON/CLI printing helpers.

## Requirements

- macOS
- Xcode installed at `/Applications/Xcode.app`
- A SUNMI printer on the same LAN as the Mac
- For LAN printing, allow Local Network access if macOS prompts for it

## Launch the SwiftUI app from Xcode

1. Clone this repository:

   ```bash
   git clone git@github.com:SaadOjo/sunmi-label-printer.git
   cd sunmi-label-printer
   ```

2. Open the SwiftUI workspace:

   ```bash
   open OJOPrintStudioSwift/OJOPrintStudioSwift.xcworkspace
   ```

3. In Xcode:
   - Select the `OJOPrintStudioSwift` scheme.
   - Select `My Mac` as the run destination.
   - Press **Run** (`Cmd + R`).

The app window should open as **OJO Print Studio Swift**.

## Launch the SwiftUI app from Terminal

From the repository root:

```bash
cd OJOPrintStudioSwift
xcodebuild -workspace OJOPrintStudioSwift.xcworkspace \
  -scheme OJOPrintStudioSwift \
  -configuration Debug \
  build

APP_PATH="$(xcodebuild -workspace OJOPrintStudioSwift.xcworkspace \
  -scheme OJOPrintStudioSwift \
  -configuration Debug \
  -showBuildSettings 2>/dev/null \
  | awk -F'= ' '
      / TARGET_BUILD_DIR = / { dir=$2 }
      / FULL_PRODUCT_NAME = / { name=$2 }
      END { print dir "/" name }
    ')"

open "$APP_PATH"
```

## Connect and print

1. Open **Connect**.
2. Click discovery/search, or enter the printer IP manually.
3. Select the discovered SUNMI printer and connect.
4. Open **Designer**.
5. Set label width, height, gap, density, and content.
6. Click **Print Label**.

Notes:

- Receipt mode uses ESC/POS.
- Label mode uses TSPL.
- The designer prints by rendering the label to a bitmap and sending TSPL `BITMAP`.
- Label media size cannot be reliably queried from the printer, so set width/height/gap manually.
- Current designer settings are saved automatically and restored when reopening the app.

## Original Objective-C reference app

The original SUNMI demo/reference app is in `MacOSApp/`.

To open it:

```bash
open MacOSApp/MacOSApp.xcworkspace
```

The SwiftUI app is the recommended app to run for current development.
