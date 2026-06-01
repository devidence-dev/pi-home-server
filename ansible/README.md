# Ansible — Configuración del Home Server

Automatización completa del servidor usando Ansible. Cubre instalación de paquetes base, Docker, zsh con oh-my-zsh, k3s y Rancher.

---

## Requisitos

- `ansible-core` >= 2.15 (`pipx install ansible-core`)
- Acceso `sudo` en el servidor destino

---

## Primeros pasos

### 1. Copiar los archivos de configuración

```bash
# Inventario (elige según tu caso)
cp inventory/local.ini.example inventory/local.ini         # si ejecutas en la misma máquina
cp inventory/production.ini.example inventory/production.ini  # si ejecutas en un servidor remoto

# Variables del host (nombre y email para Git)
cp host_vars/localhost.yml.example host_vars/localhost.yml
# Editar host_vars/localhost.yml con tus datos
```

### 2. Instalar las colecciones de Ansible

```bash
ansible-galaxy collection install -r requirements.yml
```

### 3. Ejecutar el playbook

```bash
# Local (misma máquina)
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass

# Servidor remoto
ansible-playbook main.yml -i inventory/production.ini --ask-become-pass
```

---

## Roles disponibles

### `common`
Paquetes base (`curl`, `ca-certificates`, `neovim`, `gnupg`, `git`), editor por defecto (neovim) y configuración global de Git.

### `docker`
Instala Docker CE desde el repositorio oficial. Crea el grupo `docker` y agrega el usuario configurado. Detecta la arquitectura automáticamente (`amd64` / `arm64`).

### `raspberry_pi`
Específico para Raspberry Pi: timezone, locale, expansión del filesystem y habilitación de cgroups en `cmdline.txt` (requerido para k3s). Solo se ejecuta si el hardware es una Raspberry Pi — en cualquier otra máquina se omite.

### `zsh`
Instala zsh y oh-my-zsh con los plugins `zsh-autosuggestions`, `zsh-syntax-highlighting` y `kubectl`. Genera el `.zshrc` desde un template y establece zsh como shell por defecto.

### `k3s`
Instala k3s (Kubernetes ligero) usando el script oficial. Espera a que el cluster esté disponible y copia el kubeconfig a `~/.kube/config`.

### `rancher`
Instala Rancher vía Helm sobre k3s, incluyendo `cert-manager`. **Deshabilitado por defecto** — se activa con `rancher_enabled: true`.

### `storage`
Monta una unidad de almacenamiento externa por UUID. Requiere configuración previa (ver sección Storage más abajo).

---

## Comandos útiles

### Ejecutar solo un rol específico

Cada tarea tiene tags. Puedes ejecutar solo lo que necesites:

```bash
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags common
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags docker
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags zsh
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags k3s
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags rancher
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags storage
```

### Ver qué cambiaría sin aplicar nada

```bash
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --check --diff
```

### Verificar sintaxis antes de ejecutar

```bash
ansible-playbook main.yml --syntax-check
```

### Listar todas las tareas sin ejecutarlas

```bash
ansible-playbook main.yml -i inventory/local.ini --list-tasks
```

---

## Configurar almacenamiento externo

1. Obtén el UUID del disco:
   ```bash
   blkid
   ```

2. Crea el archivo de configuración desde el ejemplo:
   ```bash
   cp roles/storage/defaults/main.yml.example roles/storage/defaults/main.yml
   ```

3. Edita `roles/storage/defaults/main.yml` con tu UUID y punto de montaje.

4. Ejecuta solo ese rol:
   ```bash
   ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags storage
   ```

---

## Activar Rancher

Rancher está deshabilitado por defecto porque requiere recursos considerables. Para activarlo:

1. Asegúrate de que k3s ya esté instalado y corriendo.

2. Añade en `host_vars/localhost.yml`:
   ```yaml
   rancher_enabled: true
   rancher_hostname: "rancher.tudominio.local"
   rancher_bootstrap_password: "una-clave-segura"
   ```

3. Ejecuta:
   ```bash
   ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags rancher
   ```

Rancher quedará disponible en `https://rancher.tudominio.local` una vez que el despliegue finalice.
