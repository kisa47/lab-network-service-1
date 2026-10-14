# Ansible

## Основные понятия
- **Ansible** — система управления конфигурациями и автоматизации ИТ-процессов.
- **Inventory** — файл со списком управляемых узлов (серверов).
- **Playbook** — YAML-файл, описывающий задачи для выполнения на хостах.
- **Role** — структурированный набор файлов (tasks, handlers, templates, vars и др.) для переиспользования.

## Структура инвентори Ansible в YAML и описание

**Инвентори** (*inventory*) в формате YAML позволяет структурировать описание серверов, групп, переменных и их взаимосвязей. Такой подход удобен для сложных инфраструктур.

## Инвентори

**Инвентори** (*inventory*) — это файл или набор файлов, где описываются управляемые хосты, группы, переменные и параметры подключения. В YAML-формате инвентори становится особенно наглядным и структурированным.

### Пример inventory.yml

```yaml
all: # группа с меречисленим всех узлов
  hosts: # хосты (виртуальные или физические машины) входящие в группу all
    web1.example.com: # хост1 c именем web1.example.com
      ansible_host: 192.168.10.10 # адрес хоста
      ansible_user: webadmin # пользователь для подключения
      http_port: 80 # переменная http_port используемая в ансибл и только для этого хоста
      app_env: production # переменная app_env

    db1.example.com: # хост 2 с именем db1.example.com
      ansible_host: 192.168.10.20
      ansible_user: dbadmin
      db_type: postgresql # переменная db_type
      db_version: 14 # переменная db_version

  children: # дочерние группы
    webservers: # группа webservers
      hosts: # хосты (виртуальные или физические машины) входящие в группу webservers
        web1.example.com: {} # хост с именем web1.example.com указанный выше
      vars: # переменные группы  webservers
        upgrade: true # переменная upgrade для группы
    dbservers:
      hosts:
        db1.example.com: {}

  vars: # переменные для группы all (всез узлов)
    ansible_connection: ssh # тип подключения ssh
    ansible_python_interpreter: /usr/bin/python3 # интерпритатор для выполнения ansible
```

### Описание основных параметров

| **Параметр** | **Описание** | **Пример** |
|----------------------------------|--------------------------------------------------------------------------|---------------------------|
| `ansible_host` | IP-адрес или домен хоста (если не совпадает с именем в инвентори) | `ansible_host: 192.168.10.10` |
| `ansible_user` | Пользователь для подключения по SSH | `ansible_user: webadmin` |
| `ansible_password` | Пароль для подключения (не рекомендуется, лучше ключ) | `ansible_password: "secretpassword"` |
| `ansible_port` | Порт для подключения (если не 22) | `ansible_port: 2222` |
| `ansible_connection` | Тип подключения (ssh, winrm, local и др.) | `ansible_connection: ssh` |
| `ansible_python_interpreter` | Путь к интерпретатору Python на хосте | `/usr/bin/python3` |

### Переменные в инвентори

- **Групповые переменные** (например, для всех веб-серверов):
```yaml
webservers:
  vars:
    http_port: 80
    max_clients: 200
```

- **Хостовые переменные** (для конкретного хоста):
```yaml
web1.example.com:
  custom_var: "value_for_web1"
```

- **Общие переменные** (для всех хостов):
```yaml
all:
  vars:
    ansible_user: deploy
    ansible_ssh_private_key_file: ~/.ssh/id_rsa
```

### Использование переменных в playbook

```yaml
- name: Настроить веб-сервер
  hosts: webservers
  tasks:
    - name: Установить nginx на порт {{ http_port }}
      apt:
        name: nginx
        state: present
```

### Дополнительные возможности

- **Группы групп** (вложенные группы):
```yaml
all:
  children:
    webservers:
      hosts:
        web1.example.com: {}
    dbservers:
      hosts:
        db1.example.com: {}
    servers: &children webservers, dbservers
```

- **Псевдонимы хостов** (если имя в инвентори отличается от реального):
```yaml
web1.example.com:
  ansible_host: 192.168.10.10
  alias: webnode01
```

### Рекомендации

- Для сложных инфраструктур разделяйте инвентори на несколько файлов и используйте директивы *group_vars/* и *host_vars/*.
- Всегда указывайте *ansible_python_interpreter*, если на сервере нестандартный путь к Python.

## Пример простого playbook (*site.yml*)
```yaml
---
- name: Обновить и перезагрузить веб-серверы
  hosts: webservers
  become: yes
  tasks:
    - name: Обновить все пакеты
      apt:
        update_cache: yes
        upgrade: dist

    - name: Перезагрузить сервер
      reboot:
```

## Запуск playbook
```bash
ansible-playbook -i inventory.ini site.yml
```

## Основные модули
- `apt` — управление пакетами (Debian/Ubuntu).
- `yum` — управление пакетами (CentOS/RHEL).
- `copy` — копирование файлов.
- `template` — копирование с обработкой Jinja2.
- `service` — управление сервисами.
- `command` / `shell` — выполнение команд.

## Переменные
- Можно задавать в `vars:` внутри playbook.
- Или в отдельных файлах `group_vars/` и `host_vars/`.

## Роли (*roles/webserver/tasks/main.yml*)
```yaml
---
- name: Установить nginx
  apt:
    name: nginx
    state: present

- name: Запустить и включить nginx
  service:
    name: nginx
    state: started
    enabled: yes
```

## Использование роли в playbook
```yaml
---
- hosts: webservers
  roles:
    - webserver
```

## Полезные команды
```bash
# Проверка синтаксиса
ansible-playbook site.yml --syntax-check

# Проверка изменений без применения (dry-run)
ansible-playbook site.yml --check

# Список задач в playbook
ansible-playbook site.yml --list-tasks

# Список хостов
ansible-inventory --list -i inventory.ini
```

## Советы
- Всегда используйте `--check` перед реальным запуском.
- Разделяйте сложные playbooks на роли для переиспользования.
- Храните секреты в Ansible Vault.
