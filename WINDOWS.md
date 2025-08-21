# Sprint 3 - Запуск на Windows

Проект полностью поддерживает Windows! VirtualBox отлично работает на Windows x64.

## Требования для Windows

### Базовые компоненты
- [VirtualBox](https://www.virtualbox.org/wiki/Downloads) (версия 6.0+)
- [Vagrant](https://www.vagrantup.com/downloads) (версия 2.0+)
- [Go](https://golang.org/dl/) (версия 1.19+)

### Для управления (выберите один вариант):

#### Вариант 1: WSL2 (Рекомендуется)
```powershell
# Установить WSL2 Ubuntu
wsl --install -d Ubuntu

# В WSL установить Ansible
sudo apt update
sudo apt install ansible
```

#### Вариант 2: Ansible для Windows
```powershell
# Установить Python
winget install Python.Python.3

# Установить Ansible через pip
pip install ansible
```

#### Вариант 3: Без Make (только PowerShell)
Можно запускать команды напрямую без Makefile.

## Установка и запуск

### С WSL2 (рекомендуется)

```powershell
# Клонировать проект в Windows
git clone <repository-url>
cd sprint3

# Войти в WSL в том же каталоге
wsl

# В WSL выполнить сборку
make vagrant-up
```

### С PowerShell + Ansible

```powershell
# Клонировать проект
git clone <repository-url>
cd sprint3

# Собрать Go приложения
cd trouble-apps-go
go mod tidy
go vet ./...

# Собрать бинарники для Linux
$env:GOOS="linux"; $env:GOARCH="amd64"
go build -o ..\ansible\files\bin\echo .\cmd\echo\main.go
go build -o ..\ansible\files\bin\trouble .\cmd\trouble\main.go  
go build -o ..\ansible\files\bin\watcher .\cmd\watcher\main.go

cd ..

# Запустить Vagrant
vagrant up
```

### Без Make (только Vagrant команды)

```powershell
# Собрать Go приложения вручную (см. выше)

# Запустить VM
vagrant up

# Подключиться к VM
vagrant ssh

# Остановить VM
vagrant halt

# Удалить VM
vagrant destroy -f
```

## Команды для PowerShell

Создайте файл `build.ps1`:

```powershell
# build.ps1
param(
    [string]$Action = "up"
)

function Build-GoApps {
    Write-Host "Building Go applications..."
    if (!(Test-Path "ansible\files\bin")) {
        New-Item -ItemType Directory -Path "ansible\files\bin" -Force
    }
    
    Push-Location trouble-apps-go
    go mod tidy
    go vet ./...
    
    $env:GOOS="linux"
    $env:GOARCH="amd64" 
    
    go build -o ..\ansible\files\bin\echo .\cmd\echo\main.go
    go build -o ..\ansible\files\bin\trouble .\cmd\trouble\main.go
    go build -o ..\ansible\files\bin\watcher .\cmd\watcher\main.go
    
    Pop-Location
    Write-Host "Go applications built successfully!"
}

switch ($Action) {
    "up" {
        Build-GoApps
        vagrant up
    }
    "ssh" {
        vagrant ssh
    }
    "destroy" {
        vagrant destroy -f
        Remove-Item -Path "storage-disk.vdi" -ErrorAction SilentlyContinue
    }
    "rebuild" {
        vagrant destroy -f
        Remove-Item -Path "storage-disk.vdi" -ErrorAction SilentlyContinue
        Build-GoApps
        vagrant up
    }
    "status" {
        vagrant status
    }
    default {
        Write-Host "Usage: .\build.ps1 [up|ssh|destroy|rebuild|status]"
    }
}
```

**Использование:**
```powershell
# Запустить VM
.\build.ps1 up

# Подключиться к VM
.\build.ps1 ssh

# Пересобрать VM
.\build.ps1 rebuild
```

## Особенности Windows

### Настройки VirtualBox
- Убедитесь, что Hyper-V отключен (конфликтует с VirtualBox)
- Включите виртуализацию в BIOS

### Проверка Hyper-V
```powershell
# Проверить статус Hyper-V
Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V

# Отключить Hyper-V (если включен)
Disable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V-All
```

### Сетевые настройки
Windows Defender может блокировать VirtualBox сети:
- Разрешите VirtualBox в Windows Defender
- Добавьте исключение для сети 192.168.56.0/24

## Доступ к сервисам

После запуска VM:

```powershell
# Веб-интерфейс trouble app
Start-Process "http://localhost:8080"

# Echo сервис через telnet
telnet localhost 8080

# SSH (если установлен OpenSSH)
ssh vagrant@192.168.56.10
# Пароль: vagrant
```

## Устранение неполадок

### Ошибка "VBoxManage не найден"
```powershell
# Добавить VirtualBox в PATH
$env:PATH += ";C:\Program Files\Oracle\VirtualBox"
```

### Ошибка Ansible на Windows
```powershell
# Установить Ansible через WSL
wsl --install -d Ubuntu
wsl -e sudo apt install ansible
```

### Проблемы с правами доступа
```powershell
# Запустить PowerShell как администратор
Start-Process powershell -Verb RunAs
```

### Ошибка компиляции Go
```powershell
# Проверить установку Go
go version

# Установить Go если отсутствует
winget install GoLang.Go
```

## Автоматическая установка зависимостей

Создайте `install-deps.ps1`:

```powershell
# install-deps.ps1
Write-Host "Installing dependencies for Sprint 3..."

# Установить через winget
winget install Oracle.VirtualBox
winget install Hashicorp.Vagrant  
winget install GoLang.Go

# Установить WSL2
wsl --install -d Ubuntu

Write-Host "Dependencies installed! Reboot may be required."
Write-Host "After reboot, run: wsl -e sudo apt install ansible"
```

## Примечания

- ✅ **VirtualBox**: Отлично работает на Windows x64
- ✅ **Vagrant**: Полная поддержка Windows
- ✅ **Go**: Нативная поддержка Windows
- ⚠️ **Ansible**: Лучше работает через WSL2
- ✅ **Все проблемы**: Корректно воспроизводятся в VM

**Windows - отличная платформа для Sprint 3!**
