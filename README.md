# Лабораторная работа по теме "Сетевые сервисы"

## Дополнительные материалы
- [Синтаксис Markdown](./extra/markdown-and-extensions.md)
- [Основные команды и работа в терминале Linux](./extra/cli-commands.md)
- [Система контроля версий Git](./extra/git.md)
- [SSH](./extra/ssh.md)
- [Network](./extra/network.md)
- [Docker](./extra/docker.md)
- [Docker Compose](./extra/docker-compose.md)
- [SpaceVM](https://docs.spacevm.ru/docs/latest/)
- [Ansible](./extra/ansible.md)
- [Администрирование информационных систем](https://kisa47.github.io/admin_lections/)

## Требования к выполнению работы

## Цель работы

- Получить практические навыки в настройке DHCP сервера
- Получить практические навыки в настройке DNS сервера

## Необходимые данные

- Подсеть: `192.168.200.0/24`
- Шлюз (Gateway): `192.168.200.1`
- DNS сервер: `192.168.200.10`
- DHCP сервер: `192.168.200.10`
- Диапазон IP адресов для выдачи DHCP: *192.168.200.100 - 192.168.200.200*
- Ip адрес, зарезервированный для **client-2**: `192.168.200.201`
- Домен (Зона): `students.vshte`
- DNS серверы для перенаправления при отсутствии записи: `8.8.8.8 8.8.4.4`


| Hostname      |          Role       |   User  | Passwodr |    MAC address    |Network settings     |Alias(cname)|
|---------------|---------------------|---------|----------|-------------------|---------------------|------------|
|**dhcp-server**| DHCP and DNS server | student | password | 52:54:00:aa:bb:01 |     static          | ns1,dhcp   |
|  **client-1** | Client              | student | password | 52:54:00:aa:bb:02 |     dhcp4           | cl1        |
|  **client-2** | Client              | student | password | 52:54:00:aa:bb:03 |dhcp4(резервирование)| cl2        |


## Подготовка к проведению практической работы 

Запустить стенд командой:
```bash
bash ./start_server.sh
```

После завершения запуска стенда необходимо проверить возможностб доступа к консоли узла **dhcp-server**. Для этого в терминале необходимо выполнить команду:

```bash
virsh  virsh --connect qemu:///system console dhcp-server
```
После чего выполнить вход в систему с учетными данными.

## Проведение лабораторной работы

### Настройка сети на узле dhcp-server

Далее необходимо создатьб директорию командой:
```bash
sudo nano /etc/netplan/50-cloud-init.yaml
```

И ввести следующие настройки:
```bash
network:
  version: 2
  ethernets:
    enp1s0:
      match:
        macaddress: "52:54:00:aa:bb:01"
      dhcp4: false
      dhcp6: false
      set-name: "enp1s0"
      addresses:
        - 192.168.10.50/24
      gateway4: 192.168.10.1
      nameservers:
        addresses: [8.8.4.4 , 8.8.8.8]
```

И применить настройки перезапустив службу командой:
```bash
sudo netplan apply
```

Проверку доступа к сети интернет можно выполнить командой:
```bash
ping vshte.ru
```

### установка DHCP и DNS сервера

Для работы необходимо установить **bind9** (dns сервис) и **isc-dhcp-server** (dhcp сервис).

```bash
sudo apt update && sudo apt install -y isc-dhcp-server bind
```

### Настройка DHCP сервера

Для начала нужно указать на каком интерфейсе будет раюотать DHCP сервер. Для этого отредактируем файл командой:
```bash
sudo nano /etc/default/isc-dhcp-server
```
и зададим для **INTERFACESv4** наш интерфейс, например `INTERFACESv4="eth0"`.

Далее отредактируем конфигруацию самого, которая находится в файле `/etc/dhcp/dhcpd.conf` и сделаем по шаблону:
```bash
option domain-name "example.org"; # Зона (домен)
option domain-name-servers 192.168.1.1; # адрес нашего DNS сервера
default-lease-time 600; # 10 минут 
max-lease-time 7200; # 2 часа

# Объявление подсети
subnet 192.168.10.0 netmask 255.255.255.0 { # указать нашу подсеть
    range 192.168.10.100 192.168.10.200;
    option routers 192.168.10.1;
    
    # Пример резервирования (статический IP по MAC-адресу)
    host some_host {
        hardware ethernet 00:1A:2B:3C:4D:5E; # mac адрес
        fixed-address 192.168.10.50; # ip
    }
}
```

После редактирования необходимо применить настройки сделав рестарт сервиса командой:
```bash
sudo systemctl restart isc-dhcp-server.service
```

И проверить на наличие ошибок командой:
```bash
systemctl status isc-dhcp-server.service
```

Если сервис в состоянии **active (running)**, значит можно переходить дальше.

### Проверка работы DHCP сервера

Выполним запуск узлов командой 
```bash
bash start_clients.sh
```

После выполнения запуска необходимо подключиться к узлу **client-1** войти с учётными данными и посмотреть, получил ли узел IP адрес по DHCP:
```bash
ip a
```
Также следует посмотреть маршрут по умолчанию командой:
```bash
ip r
```

Полученные IP адреса и маршруты необходимо вписать в разделе [Полученные результаты](#полученные-результаты).

Тоже самое необходимо проделать и для узла  **client-2**.

### Настройка DNS сервера

Для настройки DNS сервера необходимо вновь подключиться к **dhcp-server**. После подключения необходимо задать конфигурацию DNS серверу. Конфигурация задаётся в файле по пути `/etc/bind/named.conf.options` и содержимое должно быть оформлено по следующему примеру:
```bash
options {
    directory "/var/cache/bind"; // для кеша

    listen-on port 53 { 127.0.0.1; 192.168.10.2; }; # IP вашего DNS-сервера
    listen-on-v6 { none; };

    allow-query { localhost; 192.168.10.0/24; }; # Разрешаем запросы только из вашей локальной сети (указать сеть)
    allow-transfer { none; };
    # Если сервер не имеет выхода в интернет, уберите forwarders или закомментируйте
    forwarders {
        8.8.8.8;
        8.8.4.4;
    };

    recursion yes; # Разрешаем рекурсивные запросы для своих клиентов

    dnssec-validation auto;

    auth-nxdomain no;    # соответствие RFC1035
    listen-on-v6 { any; };
};
```

Далее укажим путь до фалла конфигурации зоны **students.vshte** в файле `/etc/bind/named.conf.local`:
```bash
// Прямая зона (разрешение имен в IP, указать нашу зону)
zone "office.local" { 
    type master;
    file "/etc/bind/db.office.local"; 
    allow-update { none; };
};
```

Следующим шагом создаём файл зоны **students.vshte** с путём указанным на предыдущем шаге в файле и заполняем его по следующему образцу указав необходимые адреса и имена зоны и узлов (нужны запис для всех узлов **dhcp-server**, **client-1** и **client-2**, для их псевдонимам (директива CNAME) и **gateway**):
```bash
@       IN      SOA     ns1.office.local. admin.office.local. ( 
                              2026101401      ; Serial (дата + номер версии)
                              604800          ; Refresh
                              86400           ; Retry
                              2419200         ; Expire
                              86400 )         ; Negative Cache TTL
;
; NS-серверы
@       IN      NS      ns1.office.local.
;
; серверы
ns1     IN      A       192.168.200.10      ; Сам DNS-сервер
gateway IN      A       192.168.200.1      ; Шлюз
dhcp    IN      CNAME   ns1               ; Можно указать тот же IP
;
; Клиенты
clent1 IN      A       192.168.200.201

```

Должны быть следующие записи:
- dhcp-server
- ns1
- dhcp
- client-1
- cl1
- client-2
- cl2
- gateway

После задания конфигурации перезапускаем сервис для применения настроек:
```bash
sudo systemctl restart bind9
```

и проверяем статус сервиса после рестарта:
```bash
sudo systemctl status bind9
```

Если сервис в состоянии **active (running)** можно приступать к проверке.

### Проверка DNS

подключиться к узлу **client-1** и проверить работу **forwarders** директив, выполнив команду:

```bash
ping ya,ru
```

Если запросы идут, то можно установить утилиту **nslookup** из пакета **dnsutils** командой:
```bash
sudo apt update && sudo apt install -y dnsutils
```

Далее выполним проверку как разрешается имя **gateway.students.vshte** командой:
```bash
nslookup gateway.students.vshte
```

и тут же проверим доступность:
```bash
ping -c 3 gateway.students.vshte
```
И запишем результаты в разделе [Полученные результаты](#полученные-результаты).

Также необходимо выполнить проверку для остальных узлов и записать результаты в разделе [Полученные результаты](#полученные-результаты):
- `dhcp-server.students.vshte`
- `ns1.students.vshte`
- `dhcp.students.vshte`
- `client-1.students.vshte`
- `cl1.students.vshte`
- `client-2.students.vshte`
- `cl2.students.vshte`


## Полученные результаты

ФИО:

Группа:

IP-адрес **client-1**:
Маршруты **client-1**:

IP-адрес **client-2**:
Маршруты **client-2**:

Почему **client-1** получил такой адрес:
Почему **client-2** получил такой адрес:

Вывод команды **dig gateway.students.vshte**:
```bash

```

Вывод команды **ping -n 3 gateway.students.vshte**:
```bash

```
