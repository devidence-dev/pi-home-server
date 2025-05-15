# Raspberry Pi 5 Initial Setup

This repository contains the steps for the initial configuration of a Raspberry Pi 5.

## Automatic Setup Script 🚀

To make the initial setup easier, this repository includes the `setup-pi.sh` script that automates most of the process.

### What does the script do automatically?

- Updates the operating system (`apt update && apt full-upgrade`)
- Installs required dependencies for Docker (`ca-certificates`, `curl`)
- Adds Docker's official GPG key and repository
- Installs Docker and its plugins
- Creates the `docker` group (if it doesn't exist)
- Adds your user to the `docker` group
- Installs Neovim

### What steps must you do manually?

1. Run `sudo raspi-config` to:
   - Expand the filesystem (Advanced Options > Expand Filesystem)
   - Enable autologin (System Options > Boot / Auto Login > Console Autologin)
   - Set localization (Locale, Timezone, Keyboard, WLAN Country)
2. Run `sudo nmtui` to configure a static IP if desired.
3. Reboot the Raspberry Pi (`sudo reboot`).
4. Run `newgrp docker` or log out and log back in to use Docker without sudo.

### Step-by-step script usage

1. Copy the script to your Raspberry Pi (or clone this repository).
2. Make the script executable:
   ```sh
   chmod +x setup-pi.sh
   ```
3. Run it:
   ```sh
   ./setup-pi.sh
   ```
4. Follow the instructions shown at the end of the script to complete the manual configuration.

---

## First Steps 🤔

1. After formatting the SD card, insert it into the Raspberry Pi and power it on. Check that the device receives an IP address via DHCP.

    ```shell
    ping raspberrypi.local
    PING raspberrypi.local (192.168.50.180): 56 data bytes
    64 bytes from 192.168.50.180: icmp_seq=0 ttl=64 time=94.358 ms
    64 bytes from 192.168.50.180: icmp_seq=1 ttl=64 time=26.239 ms
    64 bytes from 192.168.50.180: icmp_seq=2 ttl=64 time=5.412 ms
    ```

    In this case, the IP is `192.168.50.180`

2. Connect to the Raspberry Pi using its IP via SSH and the credentials you set when formatting the SD card:

    ```shell
    ssh piuser@192.168.50.180
    ```

3. The first step is to perform the basic Raspberry Pi configuration using:

    ```sh
    sudo raspi-config
    ```

    This will show a wizard with options to configure several settings.

    1. First, expand the root partition: Advanced Options ➜ Expand Filesystem
    2. Then enable auto-login: System Options ➜ Boot / Auto Login ➜ Console Autologin
    3. Now configure localization options: 
        1. Localisation Options ➜ Locale ➜ es_EC.UTF-8 and en_US.UTF-8
        2. Timezone ➜ Americas ➜ Guayaquil
        3. Keyboard
        4. WLAN Country ➜ Ecuador

4. After finishing, select Finish and reboot.

5. Finally, update the distribution packages:

    ```sh
    sudo apt update && sudo apt full-upgrade
    ```

## Static IP Configuration 📄

1. On the Raspberry Pi, run the following command to configure a static IP.

   ```shell
   sudo nmtui
   ```

2. In the wizard, go through the following options:

   1. NetworkManager TUI > Edit a connection > Wired connection 1 > <Edit...>

   2. IPv4 CONFIGURATION > Show > 

   3. Add the following data:

      - Addresses

        ```
        192.168.50.180/24
        ```

      - Gateway

        ```
        192.168.50.1
        ```

      - DNS servers

        ```
        1.1.1.1
        ```

        ```
        8.8.8.8
        ```

   4. To finish, apply the configuration by rebooting:

      ```shell
      sudo reboot
      ```

## Cgroup Configuration for Docker Resource Limits 🔧

To enable Docker resource limits (CPU, memory), you need to enable cgroups. This allows you to limit container resources.

### Step-by-step configuration

1. Edit the boot configuration file:
   ```shell
   sudo nano /boot/firmware/cmdline.txt
   ```

2. At the end of the line (keep everything on a single line), add:
   ```
   cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 swapaccount=1
   ```

   The complete line should look similar to:
   ```
   console=serial0,115200 console=tty1 root=PARTUUID=12345678-02 rootfstype=ext4 fsck.repair=yes rootwait cgroup_enable=cpuset cgroup_enable=memory cgroup_memory=1 swapaccount=1
   ```

3. Save the file (Press `Ctrl+O`, then `Enter`, then `Ctrl+X`).

4. Reboot your Raspberry Pi:
   ```shell
   sudo reboot
   ```

5. Verify that cgroups are enabled:
   ```shell
   cat /proc/cgroups
   ```

---

## Docker Installation :whale:

1. Set up Docker's `apt` repository.

```shell
# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
```

2. Install the Docker packages.

```shell
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

3. Create the `docker` group.

```shell
sudo groupadd docker
```

4. Add your user to the `docker` group.

```shell
sudo usermod -aG docker $USER
```

4. Log out and log back in so that your group membership is re-evaluated or apply the next command:

```shell
newgrp docker
```

5. Run `docker --version`
6. Install neovim `sudo apt-get install neovim`

## Authors and acknowledgment 🛡

Pablo Pin - devidence.dev ©

## License 🔒

Pablo Pin - devidence.dev ©
