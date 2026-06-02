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

# Host variables (Git credentials, enabled roles, etc.)
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
ansible-playbook main.yml -i inventory/local.ini

# Remote server
ansible-playbook main.yml -i inventory/production.ini
```

> 💡 If `sudo` requires a password and it's not set in `host_vars/localhost.yml`, add `--ask-become-pass`.

---

## 📐 Full Installation Order

Some roles depend on others being installed first. Follow this order on a fresh server:

**Step 1 — Base setup** (packages, Docker, zsh)
```bash
ansible-playbook main.yml -i inventory/local.ini
```
> 🍓 On Raspberry Pi this will fail on k3s with a message asking you to reboot. That is expected — continue to Step 2.

**Step 2 — Reboot** *(Raspberry Pi only — to activate cgroups)*
```bash
sudo reboot
```

**Step 3 — Install k3s**
```bash
ansible-playbook main.yml -i inventory/local.ini --tags k3s
```

**Step 4 — Install cert-manager + wildcard TLS** *(optional, requires Cloudflare token)*

Enable it in `host_vars/localhost.yml` first:
```yaml
cert_manager_enabled: true
acme_email: "your@email.com"
cloudflare_api_token: "your-token"
wildcard_domain: "lab.yourdomain.com"
```
```bash
ansible-playbook main.yml -i inventory/local.ini --tags cert_manager
```
> ⏳ Certificate issuance can take 1–3 minutes while Let's Encrypt validates the DNS challenge.

**Step 5 — Install Rancher** *(optional, requires cert_manager)*

Enable it in `host_vars/localhost.yml` first:
```yaml
rancher_enabled: true
rancher_hostname: "rancher.lab.yourdomain.com"
rancher_bootstrap_password: "your-secure-password"
```
```bash
ansible-playbook main.yml -i inventory/local.ini --tags rancher
```

**Step 6 — Storage** *(optional)*
```bash
ansible-playbook main.yml -i inventory/local.ini --tags storage
```

---

## 🧹 Clean Reinstall

Use `uninstall.yml` to wipe everything and start fresh.

```bash
ansible-playbook uninstall.yml -i inventory/local.ini
```

This removes: k3s (and everything running in it), Docker, zsh + oh-my-zsh, Helm, and the kubeconfig. Base packages installed by `common` (`git`, `neovim`, etc.) are left in place.

You can also uninstall selectively with tags:

```bash
ansible-playbook uninstall.yml -i inventory/local.ini --tags k3s
ansible-playbook uninstall.yml -i inventory/local.ini --tags docker
ansible-playbook uninstall.yml -i inventory/local.ini --tags zsh
```

### One-run reinstall

After uninstalling, a full reinstall runs in **one single command** — as long as cgroups are already active (they are if the Pi was already configured before):

```bash
ansible-playbook main.yml -i inventory/local.ini
```

> 🍓 On a **brand new Raspberry Pi** (cgroups never enabled), the first run will stop at k3s and ask for a reboot. After rebooting, re-run the same command and everything will complete. See the section below for details.

---

## 🍓 First Run on Raspberry Pi — Important

k3s requires cgroups to be active. The `raspberry_pi` role enables them by writing to `/boot/firmware/cmdline.txt`, but **a reboot is needed before they take effect**. Because of this, the first full run requires two steps:

**Step 1** — Run the full playbook. Everything installs correctly. k3s will fail with a clear message asking you to reboot first.

```bash
ansible-playbook main.yml -i inventory/local.ini
```

**Step 2** — Reboot to activate cgroups.

```bash
sudo reboot
```

**Step 3** — Re-run only k3s. All other roles will report `ok` (already installed), and k3s will install successfully.

```bash
ansible-playbook main.yml -i inventory/local.ini --tags k3s
```

On non-Raspberry Pi hardware this is not an issue — cgroups are already active and k3s installs in a single run.

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
Installs k3s (lightweight Kubernetes) using the official script. Waits for the cluster to be ready and copies the kubeconfig to `~/.kube/config`. Fails early with a helpful message if cgroups are not yet active.

### 🔐 `cert_manager`
Installs cert-manager via Helm with resource limits tuned for low-power hardware. Provisions a **wildcard Let's Encrypt certificate** (`*.yourdomain.com`) using Cloudflare DNS01 challenge — works on private networks since no inbound traffic is required. **Disabled by default** — requires a Cloudflare API token.

### 🐄 `rancher`
Installs or upgrades Rancher via Helm on top of k3s, configured to use the wildcard TLS secret generated by `cert_manager`. **Disabled by default** — enable it with `rancher_enabled: true`.

### 💾 `storage`
Mounts an external storage drive by UUID. **Disabled by default** — requires configuration before enabling (see Storage section below).

---

## 🎛️ Enabling & Disabling Roles

Each optional role is controlled by an `*_enabled` variable in `host_vars/localhost.yml`. No need to touch the playbook.

| Variable | Default | Description |
|---|---|---|
| `docker_enabled` | `true` | Install Docker CE |
| `zsh_enabled` | `true` | Install zsh + oh-my-zsh |
| `k3s_enabled` | `true` | Install k3s |
| `cert_manager_enabled` | `false` | Install cert-manager + wildcard TLS cert |
| `rancher_enabled` | `false` | Install Rancher (requires k3s + cert_manager) |
| `storage_enabled` | `false` | Mount external storage drive |

Example — run everything except Docker:

```yaml
# host_vars/localhost.yml
docker_enabled: false
```

---

## 🛠️ Useful Commands

### Run a specific role with tags

```bash
ansible-playbook main.yml -i inventory/local.ini --tags common
ansible-playbook main.yml -i inventory/local.ini --tags docker
ansible-playbook main.yml -i inventory/local.ini --tags zsh
ansible-playbook main.yml -i inventory/local.ini --tags k3s
ansible-playbook main.yml -i inventory/local.ini --tags rancher
ansible-playbook main.yml -i inventory/local.ini --tags storage
```

### Skip a specific role

```bash
ansible-playbook main.yml -i inventory/local.ini --skip-tags docker
```

### Dry run — preview changes without applying them

```bash
ansible-playbook main.yml -i inventory/local.ini --check --diff
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

4. Enable the role in `host_vars/localhost.yml`:
   ```yaml
   storage_enabled: true
   ```

5. Run the storage role:
   ```bash
   ansible-playbook main.yml -i inventory/local.ini --tags storage
   ```

---

## 🔐 Enabling cert-manager + Wildcard TLS

cert-manager provisions a wildcard Let's Encrypt certificate via Cloudflare DNS01 challenge. It works on private/local networks — no inbound traffic required, only outbound to Cloudflare's API.

### Requirements

- k3s already installed and running
- Cloudflare API token with permissions: **Zone → DNS → Edit** and **Zone → Zone → Read**

### Setup

1. Generate a Cloudflare API token from the [Cloudflare dashboard](https://dash.cloudflare.com/profile/api-tokens).

2. Add to `host_vars/localhost.yml`:
   ```yaml
   cert_manager_enabled: true
   acme_email: "your@email.com"
   cloudflare_api_token: "your-cloudflare-token"
   wildcard_domain: "lab.yourdomain.com"
   ```

3. Run:
   ```bash
   ansible-playbook main.yml -i inventory/local.ini --tags cert_manager
   ```

The role will install cert-manager, create the ClusterIssuer, request the certificate and wait up to 5 minutes for it to be issued. The resulting TLS secret (`lab-yourdomain-com-wildcard-tls`) will be available in the `cattle-system` namespace for Rancher to consume.

> ⚠️ Let's Encrypt has a rate limit of **5 certificates per domain per week**. Use the staging server for testing by setting `acme_server: "https://acme-staging-v02.api.letsencrypt.org/directory"` in `host_vars/localhost.yml`.

---

## 🐄 Enabling Rancher

Rancher requires k3s and cert-manager to be set up first.

1. Make sure both `k3s` and `cert_manager` roles have run successfully.

2. Generate a secure bootstrap password:
   ```bash
   openssl rand -base64 32
   ```

3. Add to `host_vars/localhost.yml`:
   ```yaml
   rancher_enabled: true
   rancher_hostname: "rancher.lab.yourdomain.com"
   rancher_bootstrap_password: "generated-password"
   ```

4. Run:
   ```bash
   ansible-playbook main.yml -i inventory/local.ini --tags rancher
   ```

Rancher will be available at `https://rancher.lab.yourdomain.com` with a valid TLS certificate. The bootstrap password is only used on first login — you will be prompted to change it.
