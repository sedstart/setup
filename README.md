# sedstart CLI Installer

Install **sedstart CLI** on macOS, Linux, or Windows in one command.

------------------------------------------------------------------------

# 🚀 Installation

## 🍎 macOS

``` bash
curl -fsSL https://raw.githubusercontent.com/sedstart/setup/main/install.sh | bash
```

or

``` bash
wget -qO- https://raw.githubusercontent.com/sedstart/setup/main/install.sh | bash
```

------------------------------------------------------------------------

## 🐧 Linux

``` bash
curl -fsSL https://raw.githubusercontent.com/sedstart/setup/main/install.sh | bash
```

or

``` bash
wget -qO- https://raw.githubusercontent.com/sedstart/setup/main/install.sh | bash
```

------------------------------------------------------------------------

## 🪟 Windows (PowerShell)

``` powershell
iwr https://raw.githubusercontent.com/sedstart/setup/main/install.ps1 -UseBasicParsing | iex
```

If PowerShell blocks script execution:

``` powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
iwr https://raw.githubusercontent.com/sedstart/setup/main/install.ps1 -UseBasicParsing | iex
```

------------------------------------------------------------------------

# 🧪 Installing from QA or Custom Environment

By default, the installer downloads binaries from:

    http://cli.sedstart.com/latest

You can override the base URL.

------------------------------------------------------------------------

## 🍎 macOS / 🐧 Linux (QA Example)

``` bash
curl -fsSL https://raw.githubusercontent.com/sedstart/setup/main/install.sh | bash -s -- --base-url http://qa-cli.sedstart.com/latest
```

or using environment variable:

``` bash
BASE_URL=http://qa-cli.sedstart.com/latest curl -fsSL https://raw.githubusercontent.com/sedstart/setup/main/install.sh | bash
```

------------------------------------------------------------------------

## 🪟 Windows (QA Example)

``` powershell
iex "& { $(iwr https://raw.githubusercontent.com/sedstart/setup/main/install.ps1 -UseBasicParsing) } -BaseUrl 'http://qa-cli.sedstart.com/latest'"
```

------------------------------------------------------------------------

# ✅ Verify Installation

After installation, restart your terminal and run:

``` bash
sedstart --help
```

------------------------------------------------------------------------

# 📦 Installation Details

  Platform        Install Location
  --------------- -------------------------------------------------
  macOS / Linux   `/usr/local/bin/sedstart`
  Windows         `%LOCALAPPDATA%\Programs\sedstart\sedstart.exe`

The installer automatically:

-   Detects OS and architecture
-   Downloads the correct binary
-   Sets executable permissions
-   Removes macOS quarantine flag
-   Unblocks Windows executable
-   Adds to PATH if required

------------------------------------------------------------------------

# 🔄 Update

Re-run the installation command to update to the latest version.

------------------------------------------------------------------------

# ❌ Uninstall

## macOS / Linux

``` bash
sudo rm /usr/local/bin/sedstart
```

## Windows

Delete the folder:

    %LOCALAPPDATA%\Programs\sedstart

Then remove it from your User PATH environment variable.

------------------------------------------------------------------------

# 🌍 Custom Mirrors

If you host your own binaries (enterprise, air-gapped, staging):

**macOS / Linux**

``` bash
bash install.sh --base-url <your-mirror-url>
```

**Windows**

``` powershell
install.ps1 -BaseUrl "<your-mirror-url>"
```

------------------------------------------------------------------------

# 🛠 Requirements

-   macOS 10.13+
-   Linux (glibc-based distributions)
-   Windows 10+
-   curl or wget (macOS/Linux)
-   PowerShell 5+ (Windows)

------------------------------------------------------------------------

# 💬 Support

If you encounter issues, please open an issue in this repository.
