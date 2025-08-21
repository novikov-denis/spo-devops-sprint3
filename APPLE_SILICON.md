# Sprint 3 - Запуск на Apple Silicon (ARM64) Mac

## Проблема

VirtualBox имеет ограниченную поддержку Apple Silicon Mac. При попытке запуска могут возникать ошибки:

```
VBoxManage: error: The VM session was aborted
VBoxManage: error: Details: code NS_ERROR_FAILURE (0x80004005)
```

## Рекомендуемые альтернативы

### 1. 🥇 UTM (QEMU) - РЕКОМЕНДУЕТСЯ

**Установка:**
```bash
brew install --cask utm
```

**Создание Vagrantfile для UTM:**
```ruby
# Vagrantfile-utm
Vagrant.configure("2") do |config|
  config.vm.box = "spox/ubuntu-arm" 
  # или другой ARM64 образ Ubuntu
  
  config.vm.provider :qemu do |qe|
    qe.arch = "aarch64"
    qe.machine = "virt,gic-version=max"
    qe.cpu = "max"
    qe.net_device = "virtio-net-pci"
  end
end
```

**Использование:**
```bash
# Установить QEMU провайдер для Vagrant
vagrant plugin install vagrant-qemu

# Запустить с UTM
VAGRANT_VAGRANTFILE=Vagrantfile-utm vagrant up --provider=qemu
```

### 2. 🥈 VMware Fusion (Платная)

**Vagrant настройка:**
```ruby
config.vm.provider "vmware_desktop" do |v|
  v.vmx["memsize"] = "1024"
  v.vmx["numvcpus"] = "1"
end
```

**Использование:**
```bash
# Установить VMware плагин
vagrant plugin install vagrant-vmware-desktop

# Запустить
vagrant up --provider=vmware_desktop
```

### 3. 🥉 Parallels Desktop (Платная)

**Vagrant настройка:**
```ruby
config.vm.provider "parallels" do |prl|
  prl.memory = 1024
  prl.cpus = 1
end
```

**Использование:**
```bash
# Установить Parallels плагин  
vagrant plugin install vagrant-parallels

# Запустить
vagrant up --provider=parallels
```

### 4. 🆓 Docker альтернатива

Создать Docker контейнер с systemd для части сценариев:

```dockerfile
FROM ubuntu:22.04

# Установка systemd
RUN apt-get update && apt-get install -y systemd systemd-sysv

# Копирование приложений
COPY ansible/files/bin/* /usr/local/bin/

# Настройка контейнера
CMD ["/sbin/init"]
```

**Запуск:**
```bash
docker build -t sprint3-vm .
docker run -d --privileged --name sprint3 sprint3-vm
docker exec -it sprint3 bash
```

## Текущий статус

- ✅ **Go приложения**: Собираются корректно для Linux AMD64
- ✅ **Ansible роли**: Адаптированы для локального окружения
- ✅ **Vagrant конфигурация**: Готова к использованию
- ❌ **VirtualBox**: Проблемы совместимости с Apple Silicon

## Рекомендация

**Для студентов с Apple Silicon Mac:**

1. **Лучший опыт**: UTM + QEMU провайдер
2. **Если есть бюджет**: VMware Fusion или Parallels
3. **Быстрый тест**: Docker версия (ограниченный функционал)

**Для студентов с Intel Mac или Windows/Linux:**
- Используйте стандартную VirtualBox версию без изменений

## Команды для тестирования

```bash
# Проверить архитектуру
uname -m  # arm64 = Apple Silicon

# Для Intel Mac или других платформ
make vagrant-up

# Для Apple Silicon с UTM
VAGRANT_VAGRANTFILE=Vagrantfile-utm vagrant up --provider=qemu
```
