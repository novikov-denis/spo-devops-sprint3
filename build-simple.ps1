# build-simple.ps1 - Sprint 3 VM Management Script (Simple Version)
param(
    [string]$Action = "up"
)

function Build-GoApps {
    Write-Host "Building Go applications..." -ForegroundColor Green
    
    if (!(Test-Path "ansible\files\bin")) {
        New-Item -ItemType Directory -Path "ansible\files\bin" -Force | Out-Null
    }
    
    Push-Location trouble-apps-go
    
    try {
        Write-Host "Updating Go modules..." -ForegroundColor Yellow
        go mod tidy
        
        Write-Host "Vetting Go code..." -ForegroundColor Yellow  
        go vet ./...
        
        $env:GOOS="linux"
        $env:GOARCH="amd64"
        
        Write-Host "Building echo service..." -ForegroundColor Yellow
        go build -o "..\ansible\files\bin\echo" ".\cmd\echo\main.go"
        
        Write-Host "Building trouble service..." -ForegroundColor Yellow
        go build -o "..\ansible\files\bin\trouble" ".\cmd\trouble\main.go"
        
        Write-Host "Building watcher service..." -ForegroundColor Yellow  
        go build -o "..\ansible\files\bin\watcher" ".\cmd\watcher\main.go"
        
        Write-Host "Go applications built successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "Error building Go applications: $_" -ForegroundColor Red
        exit 1
    }
    finally {
        Pop-Location
    }
}

function Check-Prerequisites {
    Write-Host "Checking prerequisites..." -ForegroundColor Yellow
    
    try {
        $goVersion = & go version 2>$null
        Write-Host "Go: $goVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "Go not found. Please install Go first." -ForegroundColor Red
        exit 1
    }
    
    try {
        $vagrantVersion = & vagrant --version 2>$null
        Write-Host "Vagrant: $vagrantVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "Vagrant not found. Please install Vagrant first." -ForegroundColor Red
        exit 1
    }
    
    try {
        $vboxVersion = & VBoxManage --version 2>$null
        Write-Host "VirtualBox: $vboxVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "VirtualBox not found." -ForegroundColor Yellow
        Write-Host "Please install VirtualBox: winget install Oracle.VirtualBox" -ForegroundColor Gray
        Write-Host "Or download from: https://www.virtualbox.org/wiki/Downloads" -ForegroundColor Gray
        Read-Host "Press Enter after installing VirtualBox"
    }
}

switch ($Action.ToLower()) {
    "up" {
        Write-Host "Starting Sprint 3 VM..." -ForegroundColor Green
        Check-Prerequisites
        Build-GoApps
        vagrant up
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "VM started successfully!" -ForegroundColor Green
            Write-Host "Web services:" -ForegroundColor Cyan
            Write-Host "- Trouble app: http://localhost:8080" -ForegroundColor Gray
            Write-Host "- Echo service: telnet localhost 8080" -ForegroundColor Gray
            Write-Host ""
            Write-Host "Connect to VM: vagrant ssh" -ForegroundColor Yellow
        }
    }
    
    "ssh" {
        Write-Host "Connecting to VM..." -ForegroundColor Green
        vagrant ssh
    }
    
    "status" {
        Write-Host "VM Status:" -ForegroundColor Green
        vagrant status
    }
    
    "provision" {
        Write-Host "Re-provisioning VM..." -ForegroundColor Green
        vagrant provision
    }
    
    "halt" {
        Write-Host "Stopping VM..." -ForegroundColor Yellow
        vagrant halt
    }
    
    "destroy" {
        Write-Host "Destroying VM..." -ForegroundColor Red
        vagrant destroy -f
        Remove-Item -Path "storage-disk.vdi" -ErrorAction SilentlyContinue
        Write-Host "VM destroyed!" -ForegroundColor Green
    }
    
    "rebuild" {
        Write-Host "Rebuilding VM from scratch..." -ForegroundColor Cyan
        vagrant destroy -f
        Remove-Item -Path "storage-disk.vdi" -ErrorAction SilentlyContinue
        Check-Prerequisites
        Build-GoApps
        vagrant up
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "VM rebuilt successfully!" -ForegroundColor Green
        }
    }
    
    "clean" {
        Write-Host "Cleaning build artifacts..." -ForegroundColor Yellow
        Remove-Item -Path "ansible\files\bin" -Recurse -ErrorAction SilentlyContinue
        Remove-Item -Path "storage-disk.vdi" -ErrorAction SilentlyContinue  
        Write-Host "Cleaned up!" -ForegroundColor Green
    }
    
    "build" {
        Write-Host "Building Go applications only..." -ForegroundColor Green
        Build-GoApps
    }
    
    "help" {
        Write-Host "Sprint 3 VM - Windows Management Script" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "Usage: .\build-simple.ps1 [action]" -ForegroundColor White
        Write-Host ""
        Write-Host "Actions:" -ForegroundColor Yellow
        Write-Host "  up       - Build Go apps and start VM" -ForegroundColor White  
        Write-Host "  ssh      - Connect to VM via SSH" -ForegroundColor White
        Write-Host "  status   - Show VM status" -ForegroundColor White
        Write-Host "  provision- Re-run Ansible provisioning" -ForegroundColor White
        Write-Host "  halt     - Stop VM" -ForegroundColor White
        Write-Host "  destroy  - Destroy VM and cleanup" -ForegroundColor White
        Write-Host "  rebuild  - Destroy and recreate VM" -ForegroundColor White
        Write-Host "  clean    - Clean build artifacts" -ForegroundColor White
        Write-Host "  build    - Build Go apps only" -ForegroundColor White
        Write-Host "  help     - Show this help" -ForegroundColor White
    }
    
    default {
        Write-Host "Unknown action: $Action" -ForegroundColor Red
        Write-Host ""
        Write-Host "Usage: .\build-simple.ps1 [up|ssh|status|provision|halt|destroy|rebuild|clean|build|help]" -ForegroundColor White
        Write-Host "Run: .\build-simple.ps1 help for detailed information" -ForegroundColor Gray
        exit 1
    }
}
