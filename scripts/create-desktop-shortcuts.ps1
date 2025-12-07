# Docker AI Agent Desktop Shortcuts Creator
# This script creates convenient desktop shortcuts for Docker AI Agent management
# Usage: powershell -ExecutionPolicy Bypass -File create-desktop-shortcuts.ps1

param(
    [string]$DesktopPath = $null,
    [switch]$AllUsers = $false,
    [switch]$RemoveShortcuts = $false,
    [switch]$Verbose = $false
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Script configuration
$ScriptConfig = @{
    AgentName = "Docker AI Agent"
    ProjectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    LogFile = Join-Path $PSScriptRoot "shortcut-creation.log"
    Icons = @{
        Start = "🟢"
        Stop = "🔴"
        Logs = "📋"
        Shell = "💻"
        Status = "📊"
    }
}

# ===========================
# Logging Functions
# ===========================

function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    Write-Host $logMessage
    Add-Content -Path $ScriptConfig.LogFile -Value $logMessage
}

function Write-Verbose-Log {
    param([string]$Message)
    
    if ($Verbose) {
        Write-Log -Message $Message -Level "DEBUG"
    }
}

# ===========================
# Path Resolution Functions
# ===========================

function Get-DesktopPath {
    param([bool]$ForAllUsers = $false)
    
    if ($ForAllUsers) {
        if ([Environment]::OSVersion.Platform -eq "Win32NT") {
            return [Environment]::GetFolderPath("CommonDesktopDirectory")
        }
    }
    
    return [Environment]::GetFolderPath("DesktopDirectory")
}

function Resolve-ProjectPath {
    param([string]$RelativePath)
    
    $fullPath = Join-Path $ScriptConfig.ProjectRoot $RelativePath
    
    if (-not (Test-Path $fullPath)) {
        Write-Verbose-Log "Path does not exist: $fullPath"
    }
    
    return $fullPath
}

# ===========================
# Shortcut Creation Functions
# ===========================

function New-DesktopShortcut {
    param(
        [string]$Name,
        [string]$TargetPath,
        [string]$Arguments,
        [string]$WorkingDirectory,
        [string]$Description,
        [string]$IconPath = $null,
        [int]$WindowStyle = 1
    )
    
    try {
        $shell = New-Object -ComObject WScript.Shell
        $shortcut = $shell.CreateShortcut($TargetPath)
        
        $shortcut.TargetPath = "powershell.exe"
        $shortcut.Arguments = "-NoExit -Command `"$Arguments`""
        $shortcut.WorkingDirectory = $WorkingDirectory
        $shortcut.Description = $Description
        $shortcut.WindowStyle = $WindowStyle
        
        if ($IconPath -and (Test-Path $IconPath)) {
            $shortcut.IconLocation = $IconPath
        }
        
        $shortcut.Save()
        
        Write-Log "Created shortcut: $Name" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Failed to create shortcut '$Name': $_" "ERROR"
        return $false
    }
}

function Create-DockerStartShortcut {
    param([string]$DesktopPath)
    
    $name = "$($ScriptConfig.AgentName) - Start"
    $shortcutPath = Join-Path $DesktopPath "Start Docker AI Agent.lnk"
    
    $commands = @(
        "cd '$($ScriptConfig.ProjectRoot)'",
        "Write-Host 'Starting Docker AI Agent...' -ForegroundColor Green",
        "docker-compose up -d",
        "Write-Host 'Docker AI Agent started successfully!' -ForegroundColor Green",
        "Write-Host 'Press any key to close...'",
        "`$null = `$Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')"
    )
    
    $targetCommand = $commands -join "; "
    
    return New-DesktopShortcut `
        -Name $name `
        -TargetPath $shortcutPath `
        -Arguments $targetCommand `
        -WorkingDirectory $ScriptConfig.ProjectRoot `
        -Description "Start the Docker AI Agent with N8N integration" `
        -WindowStyle 1
}

function Create-DockerStopShortcut {
    param([string]$DesktopPath)
    
    $name = "$($ScriptConfig.AgentName) - Stop"
    $shortcutPath = Join-Path $DesktopPath "Stop Docker AI Agent.lnk"
    
    $commands = @(
        "cd '$($ScriptConfig.ProjectRoot)'",
        "Write-Host 'Stopping Docker AI Agent...' -ForegroundColor Yellow",
        "docker-compose down",
        "Write-Host 'Docker AI Agent stopped successfully!' -ForegroundColor Green",
        "Write-Host 'Press any key to close...'",
        "`$null = `$Host.UI.RawUI.ReadKey('NoExit,IncludeKeyDown')"
    )
    
    $targetCommand = $commands -join "; "
    
    return New-DesktopShortcut `
        -Name $name `
        -TargetPath $shortcutPath `
        -Arguments $targetCommand `
        -WorkingDirectory $ScriptConfig.ProjectRoot `
        -Description "Stop the Docker AI Agent" `
        -WindowStyle 1
}

function Create-DockerLogsShortcut {
    param([string]$DesktopPath)
    
    $name = "$($ScriptConfig.AgentName) - View Logs"
    $shortcutPath = Join-Path $DesktopPath "Docker AI Agent Logs.lnk"
    
    $commands = @(
        "cd '$($ScriptConfig.ProjectRoot)'",
        "Write-Host 'Fetching Docker AI Agent logs...' -ForegroundColor Cyan",
        "docker-compose logs -f",
        "Write-Host 'Press any key to close...'",
        "`$null = `$Host.UI.RawUI.ReadKey('NoExit,IncludeKeyDown')"
    )
    
    $targetCommand = $commands -join "; "
    
    return New-DesktopShortcut `
        -Name $name `
        -TargetPath $shortcutPath `
        -Arguments $targetCommand `
        -WorkingDirectory $ScriptConfig.ProjectRoot `
        -Description "View Docker AI Agent container logs" `
        -WindowStyle 1
}

function Create-DockerShellShortcut {
    param([string]$DesktopPath)
    
    $name = "$($ScriptConfig.AgentName) - Shell"
    $shortcutPath = Join-Path $DesktopPath "Docker AI Agent Shell.lnk"
    
    $commands = @(
        "cd '$($ScriptConfig.ProjectRoot)'",
        "Write-Host 'Opening Docker AI Agent project shell...' -ForegroundColor Cyan",
        "Write-Host 'Available commands:' -ForegroundColor Green",
        "Write-Host '  docker-compose ps    - Show container status'",
        "Write-Host '  docker-compose logs  - View logs'",
        "Write-Host '  docker-compose exec [service] [command] - Execute command'",
        "''"
    )
    
    $targetCommand = $commands -join "; "
    
    return New-DesktopShortcut `
        -Name $name `
        -TargetPath $shortcutPath `
        -Arguments $targetCommand `
        -WorkingDirectory $ScriptConfig.ProjectRoot `
        -Description "Open PowerShell at project root for Docker AI Agent management" `
        -WindowStyle 1
}

function Create-DockerStatusShortcut {
    param([string]$DesktopPath)
    
    $name = "$($ScriptConfig.AgentName) - Status"
    $shortcutPath = Join-Path $DesktopPath "Docker AI Agent Status.lnk"
    
    $commands = @(
        "cd '$($ScriptConfig.ProjectRoot)'",
        "Write-Host 'Docker AI Agent Status' -ForegroundColor Cyan",
        "Write-Host '=' * 50",
        "docker-compose ps",
        "Write-Host "`n" -ForegroundColor Cyan",
        "Write-Host 'Container Details:' -ForegroundColor Green",
        "docker ps --filter 'label=com.docker.compose.project' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'",
        "Write-Host "`nPress any key to close...'",
        "`$null = `$Host.UI.RawUI.ReadKey('NoExit,IncludeKeyDown')"
    )
    
    $targetCommand = $commands -join "; "
    
    return New-DesktopShortcut `
        -Name $name `
        -TargetPath $shortcutPath `
        -Arguments $targetCommand `
        -WorkingDirectory $ScriptConfig.ProjectRoot `
        -Description "Check Docker AI Agent container status" `
        -WindowStyle 1
}

# ===========================
# Shortcut Removal Functions
# ===========================

function Remove-DesktopShortcuts {
    param([string]$DesktopPath)
    
    $shortcutNames = @(
        "Start Docker AI Agent.lnk",
        "Stop Docker AI Agent.lnk",
        "Docker AI Agent Logs.lnk",
        "Docker AI Agent Shell.lnk",
        "Docker AI Agent Status.lnk"
    )
    
    $removedCount = 0
    
    foreach ($shortcut in $shortcutNames) {
        $shortcutPath = Join-Path $DesktopPath $shortcut
        
        if (Test-Path $shortcutPath) {
            try {
                Remove-Item -Path $shortcutPath -Force
                Write-Log "Removed shortcut: $shortcut" "SUCCESS"
                $removedCount++
            }
            catch {
                Write-Log "Failed to remove shortcut '$shortcut': $_" "ERROR"
            }
        }
    }
    
    return $removedCount
}

# ===========================
# Validation Functions
# ===========================

function Test-DockerInstallation {
    try {
        $dockerVersion = docker --version
        Write-Log "Docker found: $dockerVersion" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Docker is not installed or not in PATH" "WARNING"
        return $false
    }
}

function Test-DockerComposeInstallation {
    try {
        $composeVersion = docker-compose --version
        Write-Log "Docker Compose found: $composeVersion" "SUCCESS"
        return $true
    }
    catch {
        Write-Log "Docker Compose is not installed or not in PATH" "WARNING"
        return $false
    }
}

# ===========================
# Main Execution
# ===========================

function Main {
    Write-Host "`n" + "=" * 60
    Write-Host "Docker AI Agent Desktop Shortcuts Creator"
    Write-Host "=" * 60 + "`n"
    
    # Initialize log file
    if (Test-Path $ScriptConfig.LogFile) {
        Clear-Content -Path $ScriptConfig.LogFile
    }
    
    Write-Log "Script execution started" "START"
    Write-Log "Project Root: $($ScriptConfig.ProjectRoot)"
    
    # Resolve desktop path
    $targetDesktop = if ($DesktopPath) {
        if (Test-Path $DesktopPath) {
            $DesktopPath
        }
        else {
            Write-Log "Specified desktop path does not exist: $DesktopPath" "ERROR"
            exit 1
        }
    }
    else {
        Get-DesktopPath -ForAllUsers $AllUsers
    }
    
    Write-Log "Target Desktop: $targetDesktop"
    
    # Handle shortcut removal
    if ($RemoveShortcuts) {
        Write-Host "Removing existing shortcuts..." -ForegroundColor Yellow
        $removed = Remove-DesktopShortcuts -DesktopPath $targetDesktop
        Write-Log "Removed $removed shortcut(s)" "SUCCESS"
        
        Write-Host "`nShortcuts removed successfully!" -ForegroundColor Green
        Write-Log "Script execution completed - Shortcut removal mode" "END"
        exit 0
    }
    
    # Verify Docker installation
    Write-Host "Verifying Docker installation..." -ForegroundColor Cyan
    $dockerInstalled = Test-DockerInstallation
    $composeInstalled = Test-DockerComposeInstallation
    
    if (-not ($dockerInstalled -and $composeInstalled)) {
        Write-Host "`nWarning: Docker and/or Docker Compose not found in PATH" -ForegroundColor Yellow
        Write-Host "Shortcuts will still be created, but may not work until Docker is installed." -ForegroundColor Yellow
    }
    
    # Create shortcuts
    Write-Host "`nCreating desktop shortcuts..." -ForegroundColor Cyan
    Write-Host ""
    
    $shortcutsCreated = 0
    
    if (Create-DockerStartShortcut -DesktopPath $targetDesktop) { $shortcutsCreated++ }
    if (Create-DockerStopShortcut -DesktopPath $targetDesktop) { $shortcutsCreated++ }
    if (Create-DockerLogsShortcut -DesktopPath $targetDesktop) { $shortcutsCreated++ }
    if (Create-DockerShellShortcut -DesktopPath $targetDesktop) { $shortcutsCreated++ }
    if (Create-DockerStatusShortcut -DesktopPath $targetDesktop) { $shortcutsCreated++ }
    
    # Summary
    Write-Host "`n" + "=" * 60
    Write-Host "Shortcut Creation Summary" -ForegroundColor Green
    Write-Host "=" * 60
    Write-Host "Total shortcuts created: $shortcutsCreated / 5"
    Write-Host "Desktop location: $targetDesktop"
    Write-Host "`nCreated shortcuts:"
    Write-Host "  $($ScriptConfig.Icons.Start) Start Docker AI Agent"
    Write-Host "  $($ScriptConfig.Icons.Stop) Stop Docker AI Agent"
    Write-Host "  $($ScriptConfig.Icons.Logs) Docker AI Agent Logs"
    Write-Host "  $($ScriptConfig.Icons.Shell) Docker AI Agent Shell"
    Write-Host "  $($ScriptConfig.Icons.Status) Docker AI Agent Status"
    Write-Host "`nLog file: $($ScriptConfig.LogFile)"
    Write-Host "=" * 60 + "`n"
    
    Write-Log "Script execution completed successfully" "END"
    
    if ($shortcutsCreated -eq 5) {
        exit 0
    }
    else {
        exit 1
    }
}

# Execute main function
try {
    Main
}
catch {
    Write-Log "Unexpected error: $_" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    Write-Host "`nAn error occurred. Check the log file for details." -ForegroundColor Red
    Write-Host "Log file: $($ScriptConfig.LogFile)" -ForegroundColor Red
    exit 1
}
