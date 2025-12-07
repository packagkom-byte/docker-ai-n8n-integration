# PowerShell Scripts Documentation

This directory contains PowerShell scripts for managing and automating the Docker AI n8n integration project.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Script List](#script-list)
- [Common Parameters](#common-parameters)
- [Usage Examples](#usage-examples)
- [Troubleshooting](#troubleshooting)

## Overview

These scripts automate common tasks including:
- Docker environment setup and management
- Container lifecycle management
- Configuration management
- Log monitoring and diagnostics
- Cleanup and maintenance operations

## Prerequisites

Before using these scripts, ensure you have:

- **PowerShell 5.1+** or PowerShell Core 7.x
- **Docker Desktop** installed and running
- Appropriate permissions to run PowerShell scripts
- Environment variables properly configured (if required by specific scripts)

### Execution Policy

If you encounter execution policy errors, run PowerShell as Administrator and execute:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Script List

### 1. Setup and Installation Scripts

#### `setup-environment.ps1`
**Purpose:** Initialize the development environment and configure Docker settings.

**Usage:**
```powershell
.\setup-environment.ps1 [-Environment "development"|"production"] [-ConfigFile "path/to/config"]
```

**Parameters:**
- `-Environment`: Target environment (default: "development")
- `-ConfigFile`: Path to custom configuration file (optional)

**Features:**
- Validates Docker installation
- Creates necessary directories
- Initializes configuration files
- Sets up environment variables

---

#### `install-dependencies.ps1`
**Purpose:** Install and verify all project dependencies.

**Usage:**
```powershell
.\install-dependencies.ps1 [-Force] [-Verbose]
```

**Parameters:**
- `-Force`: Force reinstall of dependencies
- `-Verbose`: Show detailed installation progress

**Features:**
- Checks Docker version compatibility
- Installs required Docker images
- Verifies network connectivity
- Creates Docker volumes if needed

---

### 2. Container Management Scripts

#### `start-containers.ps1`
**Purpose:** Start and initialize all Docker containers for the project.

**Usage:**
```powershell
.\start-containers.ps1 [-Detached] [-HealthCheck] [-Timeout 30]
```

**Parameters:**
- `-Detached`: Run containers in background (default: $true)
- `-HealthCheck`: Wait for containers to pass health checks
- `-Timeout`: Maximum wait time in seconds (default: 60)

**Features:**
- Starts containers in correct dependency order
- Validates container startup
- Performs health checks
- Displays container status

**Example:**
```powershell
.\start-containers.ps1 -HealthCheck -Timeout 120
```

---

#### `stop-containers.ps1`
**Purpose:** Gracefully stop all running Docker containers.

**Usage:**
```powershell
.\stop-containers.ps1 [-Force] [-Timeout 10]
```

**Parameters:**
- `-Force`: Force stop containers without graceful shutdown
- `-Timeout`: Grace period in seconds (default: 10)

**Features:**
- Graceful shutdown with timeout
- Preserves container state
- Cleans up resources
- Logs shutdown process

---

#### `restart-containers.ps1`
**Purpose:** Restart all or specific containers.

**Usage:**
```powershell
.\restart-containers.ps1 [-Container "name"] [-Hard]
```

**Parameters:**
- `-Container`: Specific container name (optional, all if omitted)
- `-Hard`: Perform hard restart instead of graceful

**Features:**
- Selective container restart
- Preserves data and volumes
- Reports restart status
- Validates container functionality

---

### 3. Configuration Scripts

#### `configure-environment.ps1`
**Purpose:** Update and manage environment configuration.

**Usage:**
```powershell
.\configure-environment.ps1 [-ConfigKey "key"] [-ConfigValue "value"] [-ConfigFile "path"]
```

**Parameters:**
- `-ConfigKey`: Configuration key to update
- `-ConfigValue`: New value for the key
- `-ConfigFile`: Path to configuration file

**Features:**
- Validates configuration values
- Backs up existing configuration
- Updates Docker environment variables
- Applies changes without restart (where possible)

---

#### `setup-ssl-certificates.ps1`
**Purpose:** Generate and configure SSL/TLS certificates.

**Usage:**
```powershell
.\setup-ssl-certificates.ps1 [-CertPath "path"] [-Force]
```

**Parameters:**
- `-CertPath`: Directory for certificate storage
- `-Force`: Regenerate certificates if they exist

**Features:**
- Generates self-signed certificates
- Configures certificate paths
- Sets proper permissions
- Validates certificate configuration

---

### 4. Monitoring and Logging Scripts

#### `monitor-containers.ps1`
**Purpose:** Monitor container health and performance metrics.

**Usage:**
```powershell
.\monitor-containers.ps1 [-Interval 5] [-Duration 300] [-Metrics "cpu,memory,network"]
```

**Parameters:**
- `-Interval`: Refresh interval in seconds (default: 5)
- `-Duration`: Total monitoring duration in seconds (default: unlimited)
- `-Metrics`: Comma-separated list of metrics to monitor

**Displays:**
- CPU usage
- Memory consumption
- Network I/O
- Container status
- Resource utilization trends

---

#### `collect-logs.ps1`
**Purpose:** Collect and export logs from all containers.

**Usage:**
```powershell
.\collect-logs.ps1 [-Container "name"] [-Since "2024-01-01"] [-OutputPath "logs"]
```

**Parameters:**
- `-Container`: Specific container name (optional)
- `-Since`: Start time for log collection (format: YYYY-MM-DD or relative)
- `-OutputPath`: Directory to save logs (default: "./logs")

**Features:**
- Exports logs from all containers
- Supports time-range filtering
- Creates timestamped archives
- Includes system information

**Example:**
```powershell
.\collect-logs.ps1 -Since "2 hours ago" -OutputPath "C:\logs\archive"
```

---

#### `view-logs.ps1`
**Purpose:** Real-time log viewing and filtering.

**Usage:**
```powershell
.\view-logs.ps1 [-Container "name"] [-Follow] [-Lines 100] [-Filter "keyword"]
```

**Parameters:**
- `-Container`: Container to view logs from
- `-Follow`: Follow log stream in real-time
- `-Lines`: Number of recent lines to display (default: 100)
- `-Filter`: Filter logs by keyword or pattern

**Example:**
```powershell
.\view-logs.ps1 -Container "n8n" -Follow -Filter "ERROR"
```

---

### 5. Database and Data Scripts

#### `backup-data.ps1`
**Purpose:** Create backups of database and persistent data.

**Usage:**
```powershell
.\backup-data.ps1 [-BackupPath "path"] [-Compress] [-Retention 30]
```

**Parameters:**
- `-BackupPath`: Directory for backups (default: "./backups")
- `-Compress`: Create compressed archive
- `-Retention`: Keep backups for N days (default: keep all)

**Features:**
- Full database backup
- Volume data backup
- Compression support
- Automatic cleanup of old backups

---

#### `restore-data.ps1`
**Purpose:** Restore from backup.

**Usage:**
```powershell
.\restore-data.ps1 [-BackupFile "path"] [-Force] [-Verify]
```

**Parameters:**
- `-BackupFile`: Path to backup file to restore
- `-Force`: Skip confirmation prompts
- `-Verify`: Verify restored data integrity

**Warning:** This script will overwrite existing data. Use with caution.

---

### 6. Cleanup and Maintenance Scripts

#### `clean-docker.ps1`
**Purpose:** Clean up Docker resources (unused images, volumes, etc.).

**Usage:**
```powershell
.\clean-docker.ps1 [-RemoveUnused] [-RemoveImages] [-RemoveVolumes] [-Force]
```

**Parameters:**
- `-RemoveUnused`: Remove unused containers and images
- `-RemoveImages`: Remove untagged images
- `-RemoveVolumes`: Remove unused volumes
- `-Force`: Skip confirmation prompts

**Features:**
- Identifies unused resources
- Frees disk space
- Preserves project volumes
- Provides cleanup summary

---

#### `cleanup-logs.ps1`
**Purpose:** Archive and rotate old log files.

**Usage:**
```powershell
.\cleanup-logs.ps1 [-LogPath "path"] [-RetentionDays 30] [-Archive]
```

**Parameters:**
- `-LogPath`: Directory containing logs
- `-RetentionDays`: Keep logs newer than N days
- `-Archive`: Move old logs to archive directory

---

### 7. Diagnostic and Testing Scripts

#### `diagnose-environment.ps1`
**Purpose:** Run comprehensive diagnostic checks.

**Usage:**
```powershell
.\diagnose-environment.ps1 [-Verbose] [-OutputFile "report.html"]
```

**Parameters:**
- `-Verbose`: Show detailed diagnostic information
- `-OutputFile`: Generate HTML report

**Checks:**
- Docker installation and version
- Network connectivity
- Port availability
- Environment variables
- File permissions
- Container status
- Resource availability

---

#### `test-connectivity.ps1`
**Purpose:** Test connectivity between containers and services.

**Usage:**
```powershell
.\test-connectivity.ps1 [-Container "name"] [-Service "url"] [-Timeout 5]
```

**Parameters:**
- `-Container`: Specific container to test
- `-Service`: External service URL to test
- `-Timeout`: Connection timeout in seconds

---

## Common Parameters

Many scripts support these common parameters:

- `-Verbose`: Enable verbose output
- `-WhatIf`: Show what would happen without executing
- `-Confirm`: Prompt before executing actions

## Usage Examples

### Complete Project Startup

```powershell
# 1. Setup environment
.\setup-environment.ps1 -Environment "production"

# 2. Install dependencies
.\install-dependencies.ps1 -Verbose

# 3. Configure SSL
.\setup-ssl-certificates.ps1

# 4. Start all containers
.\start-containers.ps1 -HealthCheck -Timeout 120

# 5. Verify health
.\diagnose-environment.ps1
```

### Daily Maintenance

```powershell
# Collect logs
.\collect-logs.ps1 -Since "24 hours ago"

# Monitor performance
.\monitor-containers.ps1 -Duration 600

# Clean up resources
.\clean-docker.ps1 -RemoveUnused
```

### Emergency Shutdown

```powershell
# Stop all containers
.\stop-containers.ps1 -Force

# Cleanup
.\clean-docker.ps1 -Force

# Backup critical data
.\backup-data.ps1 -Compress
```

## Troubleshooting

### Script Execution Issues

**Error: "cannot be loaded because running scripts is disabled"**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Error: "Docker daemon is not running"**
- Ensure Docker Desktop is started
- Verify Docker service is running: `Get-Service docker`

### Container Issues

**Containers won't start**
```powershell
# Diagnose the problem
.\diagnose-environment.ps1 -Verbose

# Check logs
.\view-logs.ps1 -Follow
```

**High resource usage**
```powershell
# Monitor resource consumption
.\monitor-containers.ps1 -Interval 2

# Scale back containers if needed
.\configure-environment.ps1 -ConfigKey "CONTAINER_COUNT" -ConfigValue "2"
```

### Data Issues

**Lost data - restore from backup**
```powershell
# List available backups
Get-ChildItem ./backups

# Restore specific backup
.\restore-data.ps1 -BackupFile "./backups/backup-2024-12-07.zip" -Verify
```

## Best Practices

1. **Always backup before major changes**
   ```powershell
   .\backup-data.ps1 -Compress
   ```

2. **Use `-WhatIf` to preview changes**
   ```powershell
   .\clean-docker.ps1 -RemoveUnused -WhatIf
   ```

3. **Run diagnostics after configuration changes**
   ```powershell
   .\diagnose-environment.ps1
   ```

4. **Schedule regular backups**
   - Create a Windows Task Scheduler task running `backup-data.ps1` daily

5. **Monitor container health regularly**
   ```powershell
   .\monitor-containers.ps1 -Duration 3600
   ```

## Support and Documentation

For more information:
- Check individual script headers for detailed comments
- Review Docker documentation: https://docs.docker.com/
- See main project README for architecture details

---

**Last Updated:** 2025-12-07  
**Version:** 1.0  
**Maintained by:** packagkom-byte
