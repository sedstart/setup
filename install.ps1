param(
    [string]$BaseUrl = "https://cli.sedstart.com/latest",
    # Chrome Web Store ID of the published sedstart-recorder extension (used
    # for both QA and prod - see sedstart-fe's env.qa/env.prod
    # NEXT_PUBLIC_EXTENSION_ID). Override for a dev/unpacked build's own id.
    [string]$ExtensionId = "ljijoleacnolmdmihndjdmfkfbdpkibf",
    [switch]$SkipNativeHost
)

$ErrorActionPreference = "Stop"

$BinaryName = "sedstart.exe"
# Per-user directory that is on PATH out of the box and needs no admin rights.
# Legacy installs used %LOCALAPPDATA%\Programs\sedstart.
$InstallDir = "$env:LOCALAPPDATA\Microsoft\WindowsApps"
$LegacyInstallDir = "$env:LOCALAPPDATA\Programs\sedstart"
$ManifestDir = "$env:USERPROFILE\.sedstart"
$HostName = "com.sedstart.cli"

Write-Host "🌍 Using base URL: $BaseUrl"
Write-Host "🔎 Detecting platform..."

$Arch = $env:PROCESSOR_ARCHITECTURE

switch ($Arch) {
    "AMD64" { $File = "cli_windows_amd64_v1/sedstart.exe" }
    "ARM64" { $File = "cli_windows_arm64_v8.0/sedstart.exe" }
    "x86"   { $File = "cli_windows_386_sse2/sedstart.exe" }
    default {
        Write-Host "❌ Unsupported architecture: $Arch"
        exit 1
    }
}

$Url = "$BaseUrl/$File"

Write-Host "⬇️ Downloading $Url..."

New-Item -ItemType Directory -Force -Path $InstallDir | Out-Null
Invoke-WebRequest -Uri $Url -OutFile "$InstallDir\$BinaryName"

Unblock-File "$InstallDir\$BinaryName"

# Remove an old install, but only if one exists.
$LegacyExe = "$LegacyInstallDir\$BinaryName"
if (Test-Path $LegacyExe) {
    try {
        Remove-Item -Force $LegacyExe
        Write-Host "🧹 Removed old install at $LegacyExe"
    } catch {
        Write-Host "⚠️  Could not remove old install at $LegacyExe (in use?). Delete it manually - it may shadow the new version."
    }
}

$currentPath = [Environment]::GetEnvironmentVariable("PATH", "User")

if ($currentPath -notlike "*$InstallDir*") {
    [Environment]::SetEnvironmentVariable(
        "PATH",
        "$currentPath;$InstallDir",
        "User"
    )
}

Write-Host ""
Write-Host "✅ sedstart installed successfully!"
Write-Host "Restart terminal and run: sedstart --help"

# ---------------------------------------------------------------------------
# Chrome Native Messaging host registration
#
# Lets the sedstart-recorder extension launch this CLI directly via
# chrome.runtime.connectNative() for local runs (see sedstart-be:
# cmd/sedstart/cmd/native_messaging.go and sedstart-extension:
# background/recording/nativeHost.ts). On Windows, native messaging hosts
# are registered per-browser via the registry (HKCU\Software\<Vendor>\
# NativeMessagingHosts\<host-name>, whose default value is the absolute
# path to a manifest JSON file - not a manifest *directory* the way
# macOS/Linux use) - see register-native-host.sh in sedstart-extension for
# the equivalent single-browser, manual version of this.
#
# One manifest file is written (under ~\.sedstart) and reused for
# every browser found installed - the manifest content doesn't vary by
# browser, only which registry key points at it.
# ---------------------------------------------------------------------------

function Register-NativeMessagingHosts {
    Write-Host ""
    Write-Host "🔌 Registering Chrome Native Messaging host for installed browsers..."

    New-Item -ItemType Directory -Force -Path $ManifestDir | Out-Null
    $manifestPath = "$ManifestDir\$HostName.json"
    $manifest = @{
        name             = $HostName
        description      = "Sedstart local runner native messaging host"
        path             = "$InstallDir\$BinaryName"
        type             = "stdio"
        allowed_origins  = @("chrome-extension://$ExtensionId/")
    }
    ($manifest | ConvertTo-Json) | Set-Content -Path $manifestPath -Encoding UTF8

    # label, one or more candidate install paths to probe, registry vendor
    # key under HKCU\Software\<vendor>\NativeMessagingHosts\<HostName>.
    $browsers = @(
        @{ Label = "Google Chrome"; Vendor = "Google\Chrome"; Paths = @(
            "${env:ProgramFiles}\Google\Chrome\Application\chrome.exe",
            "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
            "${env:LOCALAPPDATA}\Google\Chrome\Application\chrome.exe"
        ) },
        @{ Label = "Chromium"; Vendor = "Chromium"; Paths = @(
            "${env:ProgramFiles}\Chromium\Application\chrome.exe",
            "${env:ProgramFiles(x86)}\Chromium\Application\chrome.exe",
            "${env:LOCALAPPDATA}\Chromium\Application\chrome.exe"
        ) },
        @{ Label = "Microsoft Edge"; Vendor = "Microsoft\Edge"; Paths = @(
            "${env:ProgramFiles}\Microsoft\Edge\Application\msedge.exe",
            "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe"
        ) },
        @{ Label = "Brave Browser"; Vendor = "BraveSoftware\Brave-Browser"; Paths = @(
            "${env:ProgramFiles}\BraveSoftware\Brave-Browser\Application\brave.exe",
            "${env:ProgramFiles(x86)}\BraveSoftware\Brave-Browser\Application\brave.exe",
            "${env:LOCALAPPDATA}\BraveSoftware\Brave-Browser\Application\brave.exe"
        ) }
    )

    $anyFound = $false
    foreach ($browser in $browsers) {
        $installed = $browser.Paths | Where-Object { Test-Path $_ } | Select-Object -First 1
        if (-not $installed) {
            continue
        }
        $anyFound = $true

        $registryKey = "HKCU:\Software\$($browser.Vendor)\NativeMessagingHosts\$HostName"
        New-Item -Path $registryKey -Force | Out-Null
        Set-ItemProperty -Path $registryKey -Name "(Default)" -Value $manifestPath

        Write-Host "  ✔ $($browser.Label) ($registryKey)"
    }

    if (-not $anyFound) {
        Write-Host "  (no supported Chromium-based browser found - skipped)"
    } else {
        Write-Host "  Manifest:       $manifestPath"
        Write-Host "  Allowed origin: chrome-extension://$ExtensionId/"
    }
}

if (-not $SkipNativeHost) {
    Register-NativeMessagingHosts
}
