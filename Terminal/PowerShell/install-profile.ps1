if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# Install required modules
$modules = @('PSReadLine', 'Terminal-Icons', 'PSFzf')
foreach ($module in $modules) {
    if (-not (Get-Module -ListAvailable -Name $module)) {
        Write-Host "Installing $module..."
        Install-Module $module -Force -Scope CurrentUser
    }
}

# Check and install Python packages
function Install-PythonPackages {
    $packages = @('yfinance', 'pandas', 'matplotlib')
    
    # Try to find Anaconda installation
    $possibleCondaPaths = @(
        "$env:USERPROFILE\anaconda3\Scripts\conda.exe",
        "$env:USERPROFILE\miniconda3\Scripts\conda.exe",
        "${env:ProgramFiles}\Anaconda3\Scripts\conda.exe",
        "${env:ProgramFiles(x86)}\Anaconda3\Scripts\conda.exe"
    )
    
    $condaPath = $possibleCondaPaths | Where-Object { Test-Path $_ } | Select-Object -First 1
    
    if ($condaPath) {
        Write-Host "Found Conda at: $condaPath"
        Write-Host "Initializing Conda..."
        & $condaPath init powershell
        
        # Create temporary script for conda operations
        $tempScript = [System.IO.Path]::GetTempFileName() + ".ps1"
        @"
`$packages = @('$($packages -join "','")') 
foreach (`$package in `$packages) {
    if (-not (conda list `$package | Select-String "^`$package\s")) {
        Write-Host "Installing `$package..."
        conda install -y `$package
    } else {
        Write-Host "`$package is already installed."
    }
}
"@ | Out-File $tempScript

        # Execute in new PowerShell session
        Write-Host "Starting new PowerShell session to install packages..."
        Start-Process powershell.exe -Wait -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$tempScript`""
        
        # Cleanup
        Remove-Item $tempScript -Force
    }
    else {
        Write-Error "Conda not found. Please install Anaconda from https://www.anaconda.com/download"
        return
    }
}

# Install Python packages
Install-PythonPackages

# Profile paths
$dotfilesProfile = "$PSScriptRoot\Profile.ps1"
$profilePath = $PROFILE.CurrentUserAllHosts

# Create profile directory if it doesn't exist
$profileDir = Split-Path -Path $profilePath -Parent
if (-not (Test-Path -Path $profileDir)) {
    New-Item -ItemType Directory -Path $profileDir -Force
}

# Backup existing profile if it exists
if (Test-Path $profilePath) {
    $backupPath = "$profilePath.backup"
    Write-Host "Backing up existing profile to $backupPath"
    Copy-Item $profilePath $backupPath -Force
    Remove-Item $profilePath -Force
}

# Create symbolic link
New-Item -ItemType SymbolicLink -Path $profilePath -Target $dotfilesProfile -Force

Write-Host "PowerShell profile installation complete!"
Write-Host "Please restart your PowerShell session to apply changes."