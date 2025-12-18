# samba-timemachine-docker

This is a docker container based on Debian Trixie with SAMBA configured to provide Apple "Time Capsule" like backups.

The Docker Hub [images](https://hub.docker.com/repository/docker/timjdfletcher/samba-timemachine/tags?page=1&ordering=last_updated) support AMD64, Raspberry Pi 3/4 and other modern ARM64 based systems.

The source code is in [github](https://github.com/TimJDFletcher/dockerfiles/tree/main/samba-timemachine)

# Current Container Settings

| Variable    |              Function               |        Setting |
|-------------|:-----------------------------------:|---------------:|
| `BACKUPDIR` |  Filesystem path exported as /data  | `${BACKUPDIR}` |
| `LOG_LEVEL` |     SAMBA server logging level      | `${LOG_LEVEL}` |
| `PASS`      |        Password for the user        |      `${PASS}` |
| `PGID`      | Unix Group ID for Time Machine user |      `${PGID}` |
| `PUID`      | Unix User ID for Time Machine user  |      `${PUID}` |
| `QUOTA`     |      Time Machine Quota in GB       |     `${QUOTA}` |
| `USER`      |       Username to connect as        |      `${USER}` |

# Security

The security design is simple and assumes that timemachine backups are encrypted before leaving the source macOS system. 

# Known Bugs

I have had some macOS kernel watchdogd crashes in smbfs that I think might be related to this container, I've done the following things
to fix them:

* Switch to using trixie backports for a newer version of SAMBA
* Applied this [fix](https://community.synology.com/enu/forum/1/post/194563) to my MacBook

# Software Used

* [Debian Trixie](https://hub.docker.com/_/debian/tags?page=1&name=trixie-packports)
* [SAMBA](https://packages.debian.org/trixie/samba)
* [GOSS](https://github.com/goss-org/goss/releases)

# Getting Started with Time Machine

## 1. Connect to the Samba Share

To use a network drive for Time Machine, your Mac must first be able to see and mount the share.

1. Open **Finder**.
2. Press **Cmd + K** (or go to **Go** > **Connect to Server...**).
3. Enter the address: `smb://<SERVER_IP>:<SERVER_PORT>/Data`.
4. Enter `${USER}` as the username and `${PASS}` as the password. Select **"Remember this password in my keychain"** so Time Machine can connect automatically in the background.

---

## 2. Configure Time Machine

1. Open **System Settings** (macOS Ventura or later) or **System Preferences**.
2. Go to **General** > **Time Machine**.
3. Click **Add Backup Disk** (or the **+** icon).
4. Select your mounted Samba share from the list.
5. **Encryption:** You will be prompted to encrypt the backup. It is highly recommended to do so for network storage. You will create a separate password for the backup file itself.
6. Click **Done**. The backup will begin automatically within two minutes.

---

## 3. How to Recover Data

There are two ways to recover data: restoring specific files while your Mac is running, or performing a full system recovery if the Mac won't boot.

### A. Restoring Individual Files/Folders

If you accidentally deleted a file or need an older version of a document:

1. Ensure you are connected to the same network as your server.
2. Open the folder where the missing file used to be.
3. Click the **Time Machine icon** in the menu bar and select **Browse Time Machine Backups**.
4. Use the timeline on the right to go back in time.
5. Select the file and click **Restore**.

### B. Full System Recovery (macOS Recovery)

If your Mac is new, has a wiped drive, or won't boot, use this method:

1. **Enter Recovery Mode:**
* **Apple Silicon (M1/M2/M3/etc):** Shut down. Press and hold the **Power button** until "Loading startup options" appears. Click **Options** > **Continue**.
* **Intel Mac:** Restart and immediately hold **Cmd + R** until the Apple logo appears.


2. **Connect to Network:** Ensure your Mac is connected to Wi-Fi or Ethernet (Ethernet is much faster for a full restore).
3. **Select Restore:** Select **Restore from Time Machine** from the Utilities window.
4. **Connect to Remote Disk:** * If the Samba share doesn't appear automatically, look for a button labeled **"Other Server"** or **"Connect to Remote Disk."**
* Enter the address: `smb://<SERVER_IP>:<SERVER_PORT>/<SHARE_NAME>`.


5. **Authenticate:** Enter the server credentials of `${USER}/${PASS}`. If the backup was encrypted, you will then be asked for the **Backup Password** you created during setup.
6. **Select Backup:** Choose the date you wish to restore to and let the process complete.

---

## Important Considerations

* **Initial Backup:** The first backup is "full" and can take several hours. Use an **Ethernet cable** if possible to avoid Wi-Fi timeouts.
* **Verification:** To ensure your network backup isn't corrupted, hold the **Option (⌥)** key while clicking the Time Machine menu bar icon and select **Verify Backups**.
* **Sleep Mode:** If the backup is interrupted by the Mac sleeping, it will resume automatically when the Mac wakes up and reconnects to the network.

[Apple User Guide](https://support.apple.com/en-gb/guide/mac-help/mh35860/)

[How to recover a file](https://support.apple.com/en-gb/guide/mac-help/mh11422/)