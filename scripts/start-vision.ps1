# PowerShell Script to Check and Pull Ollama Vision Model (LLaVA)
# This script checks if the Ollama LLaVA vision model is available and pulls it if necessary
# Then opens a test page to verify the setup

# Script Configuration
$OllamaBaseUrl = "http://localhost:11434"
$ModelName = "llava"
$TestPageUrl = "http://localhost:3000"
$MaxRetries = 3
$RetryDelaySeconds = 5

# Color output for better readability
function Write-Header {
    param([string]$Message)
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "✗ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ $Message" -ForegroundColor Yellow
}

# Check if Ollama is running
function Test-OllamaConnection {
    Write-Header "Checking Ollama Connection"
    
    $retryCount = 0
    while ($retryCount -lt $MaxRetries) {
        try {
            $response = Invoke-WebRequest -Uri "$OllamaBaseUrl/api/tags" -Method Get -ErrorAction Stop -TimeoutSec 10
            if ($response.StatusCode -eq 200) {
                Write-Success "Ollama is running and accessible at $OllamaBaseUrl"
                return $true
            }
        }
        catch {
            $retryCount++
            Write-Info "Attempt $retryCount/$MaxRetries: Unable to connect to Ollama. Retrying in $RetryDelaySeconds seconds..."
            if ($retryCount -lt $MaxRetries) {
                Start-Sleep -Seconds $RetryDelaySeconds
            }
        }
    }
    
    Write-Error-Custom "Failed to connect to Ollama after $MaxRetries attempts."
    Write-Info "Please ensure Ollama is running: ollama serve"
    return $false
}

# Check if model is available
function Test-ModelAvailable {
    param([string]$Model)
    
    Write-Header "Checking for $Model Model"
    
    try {
        $response = Invoke-WebRequest -Uri "$OllamaBaseUrl/api/tags" -Method Get -ErrorAction Stop
        $models = $response.Content | ConvertFrom-Json
        
        $modelExists = $models.models | Where-Object { $_.name -like "$Model*" }
        
        if ($modelExists) {
            Write-Success "Model '$Model' is already available"
            Write-Info "Variants found: $($modelExists.name -join ', ')"
            return $true
        }
        else {
            Write-Info "Model '$Model' not found. Will attempt to pull it."
            return $false
        }
    }
    catch {
        Write-Error-Custom "Error checking model availability: $_"
        return $false
    }
}

# Pull the model
function Pull-OllamaModel {
    param([string]$Model)
    
    Write-Header "Pulling $Model Model"
    Write-Info "This may take several minutes depending on your internet connection..."
    
    try {
        $body = @{
            name = $Model
        } | ConvertTo-Json
        
        # Use streaming to show progress
        $request = [System.Net.HttpWebRequest]::CreateHttp("$OllamaBaseUrl/api/pull")
        $request.Method = "POST"
        $request.ContentType = "application/json"
        $request.Timeout = 3600000  # 1 hour timeout for large downloads
        
        $streamWriter = New-Object System.IO.StreamWriter($request.GetRequestStream())
        $streamWriter.Write($body)
        $streamWriter.Close()
        
        $response = $request.GetResponse()
        $reader = New-Object System.IO.StreamReader($response.GetResponseStream())
        
        while (($line = $reader.ReadLine()) -ne $null) {
            $progressData = $line | ConvertFrom-Json
            if ($progressData.status -eq "pulling manifest") {
                Write-Host -NoNewline "`rPulling manifest... " -ForegroundColor Yellow
            }
            elseif ($progressData.status -like "*downloading*") {
                if ($progressData.digest) {
                    $digest = $progressData.digest.Substring(0, [Math]::Min(12, $progressData.digest.Length))
                    Write-Host -NoNewline "`rDownloading $digest... " -ForegroundColor Yellow
                }
            }
            elseif ($progressData.status -eq "verifying sha256 digest") {
                Write-Host -NoNewline "`rVerifying SHA256... " -ForegroundColor Yellow
            }
            elseif ($progressData.status -eq "writing manifest") {
                Write-Host -NoNewline "`rWriting manifest... " -ForegroundColor Yellow
            }
            elseif ($progressData.status -eq "removing any unused layers") {
                Write-Host -NoNewline "`rCleaning up unused layers... " -ForegroundColor Yellow
            }
            elseif ($progressData.status -eq "success") {
                Write-Host ""
                Write-Success "Model '$Model' successfully pulled!"
                return $true
            }
        }
        
        $reader.Close()
        return $true
    }
    catch {
        Write-Error-Custom "Failed to pull model: $_"
        return $false
    }
}

# Open test page
function Open-TestPage {
    Write-Header "Opening Test Page"
    
    try {
        # Check if the test page is accessible
        $testResponse = Invoke-WebRequest -Uri $TestPageUrl -Method Head -ErrorAction Stop -TimeoutSec 5
        Write-Success "Test page is accessible at $TestPageUrl"
        
        # Open in default browser
        Start-Process $TestPageUrl
        Write-Success "Test page opened in your default browser"
        return $true
    }
    catch {
        Write-Info "Test page at $TestPageUrl is not currently accessible"
        Write-Info "This is expected if the application hasn't started yet"
        Write-Info "You can manually navigate to $TestPageUrl once the application is running"
        
        # Try to open anyway
        try {
            Start-Process $TestPageUrl
            Write-Info "Attempted to open $TestPageUrl"
        }
        catch {
            Write-Error-Custom "Could not open browser: $_"
        }
        return $false
    }
}

# Main execution
function Main {
    Write-Host "`n╔════════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║     Ollama Vision Model (LLaVA) Setup Script               ║" -ForegroundColor Cyan
    Write-Host "║     Running on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')                         ║" -ForegroundColor Cyan
    Write-Host "╚════════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    
    # Step 1: Check Ollama connection
    if (-not (Test-OllamaConnection)) {
        Write-Host "`n" -ForegroundColor Red
        exit 1
    }
    
    # Step 2: Check if model exists
    if (-not (Test-ModelAvailable -Model $ModelName)) {
        # Step 3: Pull the model if it doesn't exist
        if (-not (Pull-OllamaModel -Model $ModelName)) {
            Write-Host "`n" -ForegroundColor Red
            exit 1
        }
    }
    
    # Step 4: Verify model is now available
    Start-Sleep -Seconds 2
    if (-not (Test-ModelAvailable -Model $ModelName)) {
        Write-Error-Custom "Model verification failed after pull operation"
        exit 1
    }
    
    # Step 5: Open test page
    Open-TestPage
    
    # Summary
    Write-Header "Setup Complete"
    Write-Success "Ollama $ModelName model is ready to use!"
    Write-Info "Model API available at: $OllamaBaseUrl/api/generate"
    Write-Info "Test page: $TestPageUrl"
    Write-Host ""
}

# Run the script
Main
