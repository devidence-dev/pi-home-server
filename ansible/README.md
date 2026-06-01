# ⚙️ Ansible — Home Server Automation

Full automation for the home server setup using Ansible. Covers base packages, Docker, zsh with oh-my-zsh, k3s and Rancher.

---

## 📋 Requirements

- `ansible-core` >= 2.15 — `pipx install ansible-core`
- `sudo` access on the target server

---

## 🚀 Getting Started

### 1. Copy the configuration files

```bash
# Inventory (pick your case)
cp inventory/local.ini.example inventory/local.ini            # running on the same machine
cp inventory/production.ini.example inventory/production.ini  # running on a remote server

# Host variables (your name and email for Git)
cp host_vars/localhost.yml.example host_vars/localhost.yml
# Edit host_vars/localhost.yml with your data
```

### 2. Install Ansible collections

```bash
ansible-galaxy collection install -r requirements.yml
```

### 3. Run the playbook

```bash
# Local (same machine)
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass

# Remote server
ansible-playbook main.yml -i inventory/production.ini --ask-become-pass
```

---

## 🎭 Roles

### 📦 `common`
Base packages (`curl`, `ca-certificates`, `neovim`, `gnupg`, `git`), sets neovim as the default editor and configures global Git credentials.

### 🐳 `docker`
Installs Docker CE from the official repository. Creates the `docker` group and adds the configured user. Automatically detects architecture (`amd64` / `arm64`).

### 🍓 `raspberry_pi`
Raspberry Pi specific configuration: timezone, locale, filesystem expansion and cgroups in `cmdline.txt` (required for k3s). Automatically skipped on non-Raspberry Pi hardware.

### 🐚 `zsh`
Installs zsh and oh-my-zsh with `zsh-autosuggestions`, `zsh-syntax-highlighting` and `kubectl` plugins. Generates `.zshrc` from a template and sets zsh as the default shell.

### ☸️ `k3s`
Installs k3s (lightweight Kubernetes) using the official script. Waits for the cluster to be ready and copies the kubeconfig to `~/.kube/config`.

### 🐄 `rancher`
Installs Rancher via Helm on top of k3s, including `cert-manager`. **Disabled by default** — enable it with `rancher_enabled: true`.

### 💾 `storage`
Mounts an external storage drive by UUID. Requires prior configuration (see Storage section below).

---

## 🎛️ Enabling & Disabling Roles

Each optional role is controlled by an `*_enabled` variable in `host_vars/localhost.yml`. No need to touch the playbook.

| Variable | Default | Description |
|---|---|---|
| `docker_enabled` | `true` | Install Docker CE |
| `zsh_enabled` | `true` | Install zsh + oh-my-zsh |
| `k3s_enabled` | `true` | Install k3s |
| `rancher_enabled` | `false` | Install Rancher (requires k3s) |
| `storage_enabled` | `false` | Mount external storage drive |

Example — run everything except Docker and k3s:

```yaml
# host_vars/localhost.yml
docker_enabled: false
k3s_enabled: false
```

---

## 🛠️ Useful Commands

### Run a specific role with tags

```bash
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags common
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags docker
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags zsh
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags k3s
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags rancher
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags storage
```

### Dry run — preview changes without applying them

```bash
ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --check --diff
```

### Validate syntax before running

```bash
ansible-playbook main.yml --syntax-check
```

### List all tasks without executing

```bash
ansible-playbook main.yml -i inventory/local.ini --list-tasks
```

---

## 💾 Setting Up External Storage

1. Find your disk UUID:
   ```bash
   blkid
   ```

2. Create the config file from the example:
   ```bash
   cp roles/storage/defaults/main.yml.example roles/storage/defaults/main.yml
   ```

3. Edit `roles/storage/defaults/main.yml` with your UUID and mount point.

4. Run only the storage role:
   ```bash
   ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags storage
   ```

---

## 🐄 Enabling Rancher

Rancher is disabled by default as it requires significant resources. To enable it:

1. Make sure k3s is already installed and running.

2. Add to `host_vars/localhost.yml`:
   ```yaml
   rancher_enabled: true
   rancher_hostname: "rancher.yourdomain.local"
   rancher_bootstrap_password: "a-secure-password"
   ```

3. Run:
   ```bash
   ansible-playbook main.yml -i inventory/local.ini --ask-become-pass --tags rancher
   ```

Rancher will be available at `https://rancher.yourdomain.local` once the deployment completes.
