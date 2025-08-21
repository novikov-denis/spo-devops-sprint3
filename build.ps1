# build.ps1 - PowerShell скрипт для управления Sprint 3 VM на Windows
param(
    [string]$Action = "up"
)

function Build-GoApps {
    Write-Host "🔨 Building Go applications..." -ForegroundColor Green
    
    # Создать каталог для бинарников
    if (!(Test-Path "ansible\files\bin")) {
        New-Item -ItemType Directory -Path "ansible\files\bin" -Force | Out-Null
    }
    
    # Перейти в каталог с Go кодом
    Push-Location trouble-apps-go
    
    try {
        Write-Host "📦 Updating Go modules..." -ForegroundColor Yellow
        go mod tidy
        
        Write-Host "🔍 Vetting Go code..." -ForegroundColor Yellow  
        go vet ./...
        
        # Настройка для сборки Linux бинарников
        $env:GOOS="linux"
        $env:GOARCH="amd64"
        $env:CGO_ENABLED="1"
        
        Write-Host "🏗️  Building echo service..." -ForegroundColor Yellow
        go build -o ..\ansible\files\bin\echo .\cmd\echo\main.go
        
        Write-Host "🏗️  Building trouble service..." -ForegroundColor Yellow
        go build -o ..\ansible\files\bin\trouble .\cmd\trouble\main.go
        
        Write-Host "🏗️  Building watcher service..." -ForegroundColor Yellow  
        go build -o ..\ansible\files\bin\watcher .\cmd\watcher\main.go
        
        Write-Host "✅ Go applications built successfully!" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Error building Go applications: $_" -ForegroundColor Red
        exit 1
    }
    finally {
        Pop-Location
    }
}

function Show-Help {
    Write-Host "🚀 Sprint 3 VM - Windows Management Script" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Usage: .\build.ps1 [action]" -ForegroundColor White
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
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  .\build.ps1 up" -ForegroundColor Gray
    Write-Host "  .\build.ps1 ssh" -ForegroundColor Gray
    Write-Host "  .\build.ps1 rebuild" -ForegroundColor Gray
}

function Check-Prerequisites {
    Write-Host "🔍 Checking prerequisites..." -ForegroundColor Yellow
    
    # Проверка VirtualBox
    try {
        $vboxVersion = & VBoxManage --version 2>$null
        Write-Host "✅ VirtualBox: $vboxVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ VirtualBox not found. Please install VirtualBox first." -ForegroundColor Red
        Write-Host "   Download: https://www.virtualbox.org/wiki/Downloads" -ForegroundColor Gray
        exit 1
    }
    
    # Проверка Vagrant
    try {
        $vagrantVersion = & vagrant --version 2>$null
        Write-Host "✅ Vagrant: $vagrantVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Vagrant not found. Please install Vagrant first." -ForegroundColor Red
        Write-Host "   Download: https://www.vagrantup.com/downloads" -ForegroundColor Gray
        exit 1
    }
    
    # Проверка Go
    try {
        $goVersion = & go version 2>$null
        Write-Host "✅ Go: $goVersion" -ForegroundColor Green
    }
    catch {
        Write-Host "❌ Go not found. Please install Go first." -ForegroundColor Red
        Write-Host "   Download: https://golang.org/dl/" -ForegroundColor Gray
        exit 1
    }
}

# Главная логика
switch ($Action.ToLower()) {
    "up" {
        Check-Prerequisites
        Build-GoApps
        Write-Host "🚀 Starting Vagrant VM..." -ForegroundColor Green
        vagrant up
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "🎉 VM started successfully!" -ForegroundColor Green
            Write-Host "🌐 Web services available at:" -ForegroundColor Cyan
            Write-Host "   - Trouble app: http://localhost:8080" -ForegroundColor Gray
            Write-Host "   - Echo service: telnet localhost 8080" -ForegroundColor Gray
            Write-Host ""
            Write-Host "📝 Connect to VM: .\build.ps1 ssh" -ForegroundColor Yellow
        }
    }
    
    "ssh" {
        Write-Host "🔗 Connecting to VM..." -ForegroundColor Green
        vagrant ssh
    }
    
    "status" {
        Write-Host "📊 VM Status:" -ForegroundColor Green
        vagrant status
    }
    
    "provision" {
        Write-Host "⚙️  Re-provisioning VM..." -ForegroundColor Green
        vagrant provision
    }
    
    "halt" {
        Write-Host "⏹️  Stopping VM..." -ForegroundColor Yellow
        vagrant halt
    }
    
    "destroy" {
        Write-Host "🗑️  Destroying VM..." -ForegroundColor Red
        vagrant destroy -f
        
        Write-Host "🧹 Cleaning up files..." -ForegroundColor Yellow
        Remove-Item -Path "storage-disk.vdi" -ErrorAction SilentlyContinue
        Remove-Item -Path "console.log" -ErrorAction SilentlyContinue
        
        Write-Host "✅ VM destroyed and cleaned up!" -ForegroundColor Green
    }
    
    "rebuild" {
        Write-Host "🔄 Rebuilding VM from scratch..." -ForegroundColor Cyan
        
        # Уничтожить старую VM
        Write-Host "🗑️  Destroying old VM..." -ForegroundColor Yellow
        vagrant destroy -f
        Remove-Item -Path "storage-disk.vdi" -ErrorAction SilentlyContinue
        Remove-Item -Path "console.log" -ErrorAction SilentlyContinue
        
        # Собрать и запустить заново
        Check-Prerequisites
        Build-GoApps
        Write-Host "🚀 Starting new VM..." -ForegroundColor Green
        vagrant up
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "🎉 VM rebuilt successfully!" -ForegroundColor Green
        }
    }
    
    "clean" {
        Write-Host "🧹 Cleaning build artifacts..." -ForegroundColor Yellow
        Remove-Item -Path "ansible\files\bin" -Recurse -ErrorAction SilentlyContinue
        Remove-Item -Path "storage-disk.vdi" -ErrorAction SilentlyContinue  
        Remove-Item -Path "console.log" -ErrorAction SilentlyContinue
        Write-Host "✅ Cleaned up!" -ForegroundColor Green
    }
    
    "help" {
        Show-Help
    }
    
    default {
        Write-Host "❌ Unknown action: $Action" -ForegroundColor Red
        Write-Host ""
        Show-Help
        exit 1
    }
}
