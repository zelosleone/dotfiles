
# Define paths
$sourceConfigPath = Join-Path $PSScriptRoot "settings.json"
$terminalConfigDir = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState"
$targetConfigPath = Join-Path $terminalConfigDir "settings.json"

# Create directory if it doesn't exist
if (!(Test-Path $terminalConfigDir)) {
    New-Item -ItemType Directory -Path $terminalConfigDir -Force
}

# Backup existing config if it exists
if (Test-Path $targetConfigPath) {
    $backupPath = "$targetConfigPath.backup"
    Write-Host "Creating backup of existing config at $backupPath"
    Copy-Item -Path $targetConfigPath -Destination $backupPath -Force
}

# Copy new config
Write-Host "Installing new Windows Terminal configuration..."
Copy-Item -Path $sourceConfigPath -Destination $targetConfigPath -Force