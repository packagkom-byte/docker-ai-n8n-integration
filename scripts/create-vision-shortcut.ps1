# PowerShell Script to Create Vision Model Shortcut and Setup
# Purpose: Automates Vision model configuration and shortcut creation
# Author: packagkom-byte
# Date: 2025-12-07
# Version: 1.0

param(
    [Parameter(Mandatory=$false)]
    [string]$VisionModelName = "vision-model",
    
    [Parameter(Mandatory=$false)]
    [string]$ShortcutPath = "$env:APPDATA\Vision Model Shortcuts",
    
    [Parameter(Mandatory=$false)]
    [string]$ConfigPath = ".",
    
    [Parameter(Mandatory=$false)]
    [switch]$CreateDesktopShortcut,
    
    [Parameter(Mandatory=$false)]
    [switch]$Force
)

# Set strict error handling
$ErrorActionPreference = "Stop"

# Script configuration
$scriptVersion = "1.0"
$logFile = "vision-model-setup.log"

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Write-Log {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("INFO", "WARN", "ERROR", "SUCCESS")]
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Write-Host $logMessage
    Add-Content -Path $logFile -Value $logMessage -ErrorAction SilentlyContinue
}

function Test-AdminPrivileges {
    $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    return $isAdmin
}

function Create-VisionModelDirectory {
    param(
        [string]$Path
    )
    
    Write-Log "Creating Vision Model directory structure at: $Path" "INFO"
    
    try {
        if (-not (Test-Path -Path $Path)) {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            Write-Log "Directory created successfully: $Path" "SUCCESS"
        } else {
            Write-Log "Directory already exists: $Path" "INFO"
        }
        
        return $true
    } catch {
        Write-Log "Failed to create directory: $_" "ERROR"
        return $false
    }
}

function Create-ConfigurationFile {
    param(
        [string]$Path,
        [string]$ModelName
    )
    
    Write-Log "Creating Vision model configuration file" "INFO"
    
    $configContent = @"
# Vision Model Configuration
# Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

[Model]
Name=$ModelName
Type=Vision
Status=Active
CreatedDate=$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

[Settings]
EnableLogging=true
LogLevel=INFO
CacheEnabled=true
CachePath=./cache

[Integration]
Framework=n8n
DockerSupport=true
ContainerName=vision-model-container

[Paths]
ConfigPath=$Path
DataPath=$Path/data
ModelsPath=$Path/models
LogsPath=$Path/logs
"@
    
    try {
        $configFile = Join-Path -Path $Path -ChildPath "vision-model.conf"
        Set-Content -Path $configFile -Value $configContent -Force
        Write-Log "Configuration file created: $configFile" "SUCCESS"
        return $configFile
    } catch {
        Write-Log "Failed to create configuration file: $_" "ERROR"
        return $null
    }
}

function Create-WindowsShortcut {
    param(
        [string]$ShortcutPath,
        [string]$TargetPath,
        [string]$Description
    )
    
    Write-Log "Creating Windows shortcut" "INFO"
    
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $shortcut = $WshShell.CreateShortcut($ShortcutPath)
        $shortcut.TargetPath = $targetPath
        $shortcut.WorkingDirectory = Split-Path -Parent $targetPath
        $shortcut.Description = $Description
        $shortcut.Save()
        
        Write-Log "Shortcut created successfully: $ShortcutPath" "SUCCESS"
        return $true
    } catch {
        Write-Log "Failed to create shortcut: $_" "ERROR"
        return $false
    }
}

function Create-PowerShellShortcut {
    param(
        [string]$Path,
        [string]$ScriptPath,
        [string]$ScriptName
    )
    
    Write-Log "Creating PowerShell launch shortcut" "INFO"
    
    $shortcutContent = @"
# PowerShell Shortcut for Vision Model
# Auto-generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

param(
    [switch]`$Admin,
    [switch]`$Config
)

`$visionModelPath = "$ScriptPath"

if (`$Admin) {
    if (-not (Test-AdminPrivileges)) {
        Write-Host "Elevating to Administrator privileges..."
        Start-Process powershell.exe -ArgumentList "-NoExit -Command & `"$ScriptPath`"" -Verb RunAs
    }
} 

if (`$Config) {
    Write-Host "Opening Vision Model Configuration..."
    & "$ScriptPath"
}

Write-Host "Vision Model environment loaded"
"@
    
    try {
        $shortcutFile = Join-Path -Path $Path -ChildPath "$ScriptName.ps1"
        Set-Content -Path $shortcutFile -Value $shortcutContent -Force
        Write-Log "PowerShell shortcut created: $shortcutFile" "SUCCESS"
        return $shortcutFile
    } catch {
        Write-Log "Failed to create PowerShell shortcut: $_" "ERROR"
        return $null
    }
}

function Create-DesktopShortcut {
    param(
        [string]$ModelName,
        [string]$TargetScript
    )
    
    Write-Log "Creating Desktop shortcut" "INFO"
    
    $desktopPath = [Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path -Path $desktopPath -ChildPath "$ModelName.lnk"
    
    try {
        $WshShell = New-Object -ComObject WScript.Shell
        $shortcut = $WshShell.CreateShortcut($shortcutPath)
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-NoExit -File `"$TargetScript`""
        $shortcut.WorkingDirectory = Split-Path -Parent $TargetScript
        $shortcut.Description = "Vision Model Launcher"
        $shortcut.IconLocation = "powershell.exe,0"
        $shortcut.Save()
        
        Write-Log "Desktop shortcut created: $shortcutPath" "SUCCESS"
        return $true
    } catch {
        Write-Log "Failed to create Desktop shortcut: $_" "ERROR"
        return $false
    }
}

function Initialize-SubDirectories {
    param(
        [string]$BasePath
    )
    
    Write-Log "Initializing subdirectories" "INFO"
    
    $subdirectories = @(
        "data",
        "models",
        "logs",
        "cache",
        "config"
    )
    
    foreach ($subdir in $subdirectories) {
        $fullPath = Join-Path -Path $BasePath -ChildPath $subdir
        if (-not (Test-Path -Path $fullPath)) {
            New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
            Write-Log "Subdirectory created: $fullPath" "SUCCESS"
        }
    }
}

function Create-ReadmeFile {
    param(
        [string]$Path,
        [string]$ModelName
    )
    
    Write-Log "Creating README documentation" "INFO"
    
    $readmeContent = @"
# Vision Model Setup

## Overview
This directory contains the Vision Model configuration and shortcuts for the n8n Docker AI integration.

## Model Information
- **Name:** $ModelName
- **Type:** Vision Model
- **Framework:** n8n
- **Docker Support:** Yes
- **Created:** $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')

## Directory Structure
```
vision-model/
├── config/           # Configuration files
├── data/             # Data storage
├── models/           # Model files
├── logs/             # Application logs
├── cache/            # Cache directory
└── vision-model.conf # Main configuration
```

## Getting Started

### Prerequisites
- PowerShell 5.1 or higher
- Docker (for containerized setup)
- n8n installation

### Usage

#### Launch Vision Model
``powershell
.\vision-model-launcher.ps1
``

#### With Administrator Privileges
``powershell
.\vision-model-launcher.ps1 -Admin
``

#### Open Configuration
``powershell
.\vision-model-launcher.ps1 -Config
``

## Configuration

Edit `vision-model.conf` to customize:
- Model name and type
- Logging settings
- Cache configuration
- Integration parameters

## Logging

Logs are stored in the `logs/` directory. Check `vision-model-setup.log` for initialization logs.

## Troubleshooting

### Permission Denied
Run PowerShell as Administrator:
``powershell
Start-Process powershell -Verb RunAs
``

### Docker Issues
Ensure Docker service is running:
``powershell
docker ps
``

## Support
For issues or questions, refer to the main docker-ai-n8n-integration repository documentation.

---
Generated by create-vision-shortcut.ps1 on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
"@
    
    try {
        $readmeFile = Join-Path -Path $Path -ChildPath "README.md"
        Set-Content -Path $readmeFile -Value $readmeContent -Force
        Write-Log "README created: $readmeFile" "SUCCESS"
        return $readmeFile
    } catch {
        Write-Log "Failed to create README: $_" "ERROR"
        return $null
    }
}

function Validate-Setup {
    param(
        [string]$Path
    )
    
    Write-Log "Validating Vision Model setup" "INFO"
    
    $requiredFiles = @(
        "vision-model.conf",
        "vision-model-launcher.ps1",
        "README.md"
    )
    
    $requiredDirs = @(
        "data",
        "models",
        "logs",
        "cache",
        "config"
    )
    
    $validationPassed = $true
    
    # Check files
    foreach ($file in $requiredFiles) {
        $filePath = Join-Path -Path $Path -ChildPath $file
        if (Test-Path -Path $filePath) {
            Write-Log "✓ Found: $file" "SUCCESS"
        } else {
            Write-Log "✗ Missing: $file" "WARN"
            $validationPassed = $false
        }
    }
    
    # Check directories
    foreach ($dir in $requiredDirs) {
        $dirPath = Join-Path -Path $Path -ChildPath $dir
        if (Test-Path -Path $dirPath) {
            Write-Log "✓ Found directory: $dir" "SUCCESS"
        } else {
            Write-Log "✗ Missing directory: $dir" "WARN"
            $validationPassed = $false
        }
    }
    
    return $validationPassed
}

# ============================================================================
# MAIN EXECUTION
# ============================================================================

function Main {
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Vision Model Shortcut & Setup Creator" -ForegroundColor Cyan
    Write-Host "Version: $scriptVersion" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    
    Write-Log "Script execution started" "INFO"
    Write-Log "Parameters: ModelName=$VisionModelName, ShortcutPath=$ShortcutPath, CreateDesktopShortcut=$CreateDesktopShortcut" "INFO"
    
    # Resolve full paths
    $resolvedShortcutPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($ShortcutPath)
    
    # Step 1: Create directories
    Write-Host "`n[1/6] Creating directories..." -ForegroundColor Yellow
    if (-not (Create-VisionModelDirectory -Path $resolvedShortcutPath)) {
        Write-Log "Failed to create Vision Model directory" "ERROR"
        exit 1
    }
    
    # Step 2: Initialize subdirectories
    Write-Host "`n[2/6] Initializing subdirectories..." -ForegroundColor Yellow
    Initialize-SubDirectories -BasePath $resolvedShortcutPath
    
    # Step 3: Create configuration file
    Write-Host "`n[3/6] Creating configuration file..." -ForegroundColor Yellow
    $configFile = Create-ConfigurationFile -Path $resolvedShortcutPath -ModelName $VisionModelName
    if (-not $configFile) {
        Write-Log "Failed to create configuration" "ERROR"
        exit 1
    }
    
    # Step 4: Create PowerShell launcher shortcut
    Write-Host "`n[4/6] Creating PowerShell launcher..." -ForegroundColor Yellow
    $launcherScript = Create-PowerShellShortcut -Path $resolvedShortcutPath -ScriptPath $resolvedShortcutPath -ScriptName "vision-model-launcher"
    if (-not $launcherScript) {
        Write-Log "Failed to create launcher script" "ERROR"
        exit 1
    }
    
    # Step 5: Create Desktop shortcut (optional)
    if ($CreateDesktopShortcut) {
        Write-Host "`n[5/6] Creating Desktop shortcut..." -ForegroundColor Yellow
        if (-not (Create-DesktopShortcut -ModelName $VisionModelName -TargetScript $launcherScript)) {
            Write-Log "Failed to create Desktop shortcut" "WARN"
        }
    } else {
        Write-Host "`n[5/6] Skipping Desktop shortcut (use -CreateDesktopShortcut to enable)" -ForegroundColor Gray
    }
    
    # Step 6: Create documentation
    Write-Host "`n[6/6] Creating documentation..." -ForegroundColor Yellow
    $readmeFile = Create-ReadmeFile -Path $resolvedShortcutPath -ModelName $VisionModelName
    
    # Validate setup
    Write-Host "`nValidating setup..." -ForegroundColor Yellow
    $validationResult = Validate-Setup -Path $resolvedShortcutPath
    
    # Summary
    Write-Host "`n========================================" -ForegroundColor Cyan
    Write-Host "Setup Complete!" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "Vision Model: $VisionModelName" -ForegroundColor Green
    Write-Host "Location: $resolvedShortcutPath" -ForegroundColor Green
    Write-Host "Launcher: $launcherScript" -ForegroundColor Green
    Write-Host "Validation: $(if ($validationResult) { 'PASSED ✓' } else { 'WARNINGS ⚠' })" -ForegroundColor $(if ($validationResult) { 'Green' } else { 'Yellow' })
    Write-Host ""
    
    Write-Log "Script execution completed successfully" "SUCCESS"
}

# Execute main function
try {
    Main
} catch {
    Write-Log "Script error: $_" "ERROR"
    Write-Host "Script encountered an error. Check $logFile for details." -ForegroundColor Red
    exit 1
}
