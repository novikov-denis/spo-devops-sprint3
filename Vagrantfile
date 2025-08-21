# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  # Базовый образ Ubuntu 22.04 LTS
  config.vm.box = "ubuntu/jammy64"
  config.vm.box_version = ">= 20230425.0.0"
  
  # Настройки виртуальной машины
  config.vm.hostname = "sprint3-vm"
  
  # Настройки VirtualBox
  config.vm.provider "virtualbox" do |vb|
    vb.name = "sprint3-vm"
    vb.memory = "1024"  # Уменьшено для совместимости
    vb.cpus = 1
    
    # Создаем дополнительный диск для storage задач (временно отключено для диагностики)
    # unless File.exist?("./storage-disk.vdi")
    #   vb.customize ["createhd", "--filename", "./storage-disk.vdi", "--size", "5120"]
    # end
    # vb.customize ["storageattach", :id, "--storagectl", "SCSI", "--port", "2", "--device", "0", "--type", "hdd", "--medium", "./storage-disk.vdi"]
    
    # Отключаем Serial консоль для начала
    # vb.customize ["modifyvm", :id, "--uart1", "0x3F8", "4"]
    # vb.customize ["modifyvm", :id, "--uartmode1", "file", File.join(Dir.pwd, "console.log")]
  end

  # Сетевые настройки
  # Приватная сеть для доступа к веб-сервисам
  config.vm.network "private_network", ip: "192.168.56.10"
  
  # Проброс портов для тестирования сервисов
  config.vm.network "forwarded_port", guest: 8080, host: 8080, host_ip: "127.0.0.1"
  config.vm.network "forwarded_port", guest: 80, host: 8081, host_ip: "127.0.0.1"

  # Синхронизация папок - отключаем стандартную для безопасности
  config.vm.synced_folder ".", "/vagrant", disabled: true
  
  # Копируем только необходимые файлы
  config.vm.synced_folder "./ansible", "/tmp/ansible", type: "rsync", rsync__exclude: [".git/", "*.log"]
  config.vm.synced_folder "./trouble-apps-go", "/tmp/trouble-apps-go", type: "rsync", rsync__exclude: [".git/", "*.log"]

  # SSH настройки
  config.ssh.insert_key = false
  config.ssh.forward_agent = true

  # Provision с помощью Ansible
  config.vm.provision "ansible" do |ansible|
    ansible.playbook = "ansible/playbook-vagrant.yml"
    ansible.inventory_path = "ansible/inventory-vagrant"
    ansible.limit = "all"
    ansible.verbose = "v"
    
    # Дополнительные переменные для Vagrant окружения
    ansible.extra_vars = {
      vagrant_environment: true,
      storage_device: "/dev/sdc",  # В VirtualBox дополнительный диск обычно /dev/sdc
      base_device: "/dev/sda"      # Основной диск в Vagrant обычно /dev/sda
    }
  end

  # Post-provision сообщение
  config.vm.post_up_message = <<-MSG
    ====================================
    Sprint 3 VM готова к использованию!
    
    Доступ к машине: vagrant ssh
    
    Веб-сервисы:
    - Trouble app: http://localhost:8080
    - Echo service: telnet localhost 8080
    
    Проблемы для диагностики:
    - Файловая система: поврежденный XFS на /dev/sdc
    - DNS: некорректный nsswitch.conf
    - GRUB: сломанные пути к дискам
    - Ulimit: ограничения на открытые файлы
    - Services: конфликты блокировок файлов
    
    Флаги спрятаны в различных местах системы.
    Удачной диагностики!
    ====================================
  MSG
end
