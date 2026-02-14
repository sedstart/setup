param(
    [string]$BaseUrl = "http://cli.sedstart.com/latest"
)

$ErrorActionPreference = "Stop"

$BinaryName = "sedstart.exe"
$InstallDir = "$env:LOCALAPPDATA\Programs\sedstart"

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
