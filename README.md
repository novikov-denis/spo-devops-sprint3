# Sprint 3 - Диагностика Linux систем

Учебная виртуальная машина с намеренно внедренными проблемами для обучения диагностике Linux-систем.

## Требования

- [Vagrant](https://www.vagrantup.com/) (версия 2.0+)
- [VirtualBox](https://www.virtualbox.org/) (версия 6.0+) **ИЛИ** другой гипервизор
- [Go](https://golang.org/) (версия 1.19+) для сборки приложений
- [Ansible](https://www.ansible.com/) (версия 2.9+)

**⚠️ Для Apple Silicon Mac:** VirtualBox имеет проблемы совместимости. См. [APPLE_SILICON.md](APPLE_SILICON.md) для альтернатив.

**✅ Для Windows:** Полная поддержка! См. [WINDOWS.md](WINDOWS.md) для подробных инструкций.

## Быстрый старт

### Linux / macOS (Intel)
```bash
# Клонируйте репозиторий
git clone <repository-url>
cd sprint3

# Запустите виртуальную машину (автоматически соберет Go приложения)
make vagrant-up

# Подключитесь к машине
make vagrant-ssh
```

### Windows
```powershell
# Клонируйте репозиторий
git clone <repository-url>
cd sprint3

# Запустите виртуальную машину
.\build.ps1 up

# Подключитесь к машине
.\build.ps1 ssh
```

### Apple Silicon Mac
См. [APPLE_SILICON.md](APPLE_SILICON.md) для альтернативных способов запуска.

## Доступные команды

### Linux / macOS
```bash
make vagrant-up       # Создать и запустить VM
make vagrant-ssh      # Подключиться к VM  
make vagrant-provision # Перепровизионить VM (применить изменения)
make vagrant-status   # Показать статус VM
make vagrant-rebuild  # Полностью пересобрать VM с нуля
make vagrant-destroy  # Удалить VM и очистить файлы

make build           # Alias для vagrant-up (обратная совместимость)
make clean           # Очистить артефакты сборки
```

### Windows PowerShell
```powershell
.\build.ps1 up        # Создать и запустить VM
.\build.ps1 ssh       # Подключиться к VM
.\build.ps1 provision # Перепровизионить VM
.\build.ps1 status    # Показать статус VM
.\build.ps1 rebuild   # Полностью пересобрать VM с нуля
.\build.ps1 destroy   # Удалить VM и очистить файлы
.\build.ps1 clean     # Очистить артефакты сборки
.\build.ps1 help      # Показать справку
```

## Сетевой доступ

После запуска доступны:

- **Trouble Web App**: http://localhost:8080
- **Echo TCP Service**: `telnet localhost 8080`
- **SSH доступ**: `vagrant ssh` или `ssh vagrant@192.168.56.10`

## Встроенные проблемы

### 🗄️ Проблемы файловой системы
- Поврежденная XFS файловая система на `/dev/sdc1` (LVM)
- Скрытые флаги в различных частях ФС
- Примонтированная система в `/opt/devops`

### 🚀 Проблемы загрузки  
- Сломанные пути дисков в GRUB (`/dev/sda` → `/dev/vda`)
- Модифицированная конфигурация загрузчика

### 🌐 Сетевые проблемы
- Поврежденный `/etc/nsswitch.conf` (отсутствует DNS в hosts resolution)
- Настройки могут влиять на разрешение имен

### ⚙️ Проблемы ресурсов
- Крайне низкие ulimit для открытых файлов (1024)
- Приложения могут падать из-за нехватки дескрипторов

### 🔒 Проблемы блокировок файлов
- Конкурирующие systemd сервисы
- Файл `/locks/lockfile.lock` используется несколькими процессами
- `watcher.path` мониторит изменения и перезапускает сервисы

## Приложения для диагностики

### Echo Service (порт 8080)
- TCP сервер, возвращающий флаг в base64
- Systemd сервис: `echo.service`
- Исполняемый файл: `/usr/local/bin/echo`

### Trouble Web App (порт 8080)  
- HTTP сервер с особой логикой
- Возвращает флаг только при заголовке `Connection: close`
- Исполняемый файл: `/opt/devops/bin/trouble`

### Watcher Service
- Блокирует файл `/locks/lockfile.lock`
- Управляется через `locker.service` и `watcher.path`
- Исполняемый файл: `/usr/local/bin/watcher`

## Поиск флагов

В системе спрятаны флаги в формате `FLAG: XXXXXXXX`. Их можно найти:

- В поврежденных файловых системах
- В логах и конфигах системы  
- В выводе приложений (при правильном обращении)
- В различных частях системы

## Структура проекта

```
sprint3/
├── Vagrantfile                 # Конфигурация Vagrant
├── Makefile                    # Автоматизация сборки
├── ansible/
│   ├── playbook-vagrant.yml    # Ansible playbook для VM
│   ├── inventory-vagrant       # Инвентарь Vagrant
│   └── roles/                  # Ansible роли с проблемами
└── trouble-apps-go/            # Go приложения
    ├── cmd/                    # Исполняемые файлы
    └── internal/               # Внутренние пакеты
```

## Отладка

### Логи виртуальной машины
```bash
# Vagrant логи
vagrant up --debug

# Серийная консоль (для проблем с GRUB)
tail -f console.log

# Логи провизионинга
vagrant provision --debug
```

### Диагностика системы
```bash
# После подключения к VM
vagrant ssh

# Проверить systemd сервисы
systemctl status echo watcher locker

# Проверить файловые системы  
df -h
lsblk
mount | grep opt

# Проверить ulimit
ulimit -n

# Проверить блокировки файлов
lsof /locks/lockfile.lock
```

## Сброс состояния

```bash
# Полный сброс
make vagrant-destroy
make vagrant-up

# Только повторное провизионирование
make vagrant-provision
```

## Устранение неполадок

### Ошибка VirtualBox на Apple Silicon

```
VBoxManage: error: The VM session was aborted
```

**Решение**: Используйте альтернативный гипервизор. См. [APPLE_SILICON.md](APPLE_SILICON.md)

### Ошибка компиляции Go

```
make: *** [go-clean] Error 127
```

**Решение**: Проблема с пробелами в пути. Используйте каталог без пробелов или обновите до последней версии.

### Недостаточно ресурсов

```
Vagrant: The guest machine entered an invalid state
```

**Решение**: Увеличьте память в Vagrantfile:
```ruby
vb.memory = "2048"  # вместо 1024
```

## Примечания

- VM создает дополнительный диск `storage-disk.vdi` для имитации проблем с разделами
- Все изменения в коде приложений требуют пересборки (`make vagrant-provision`)
- Сетевые интерфейсы настроены на `192.168.56.10` (приватная сеть)
- SSH ключи управляются Vagrant автоматически

---

**Удачной диагностики! 🔍**