# Deployment

## Linux (Precompiled Binary)

Supported architectures: armv6/v7, arm64, amd64. Tested on Debian-based distributions.

### Automated Install

```bash
wget -O install.sh https://raw.githubusercontent.com/tobychui/arozos/master/installer/install.sh
bash install.sh
```

Follow the on-screen prompts. If you selected systemd installation:

```bash
sudo systemctl status arozos
```

### Manual Install

1. Download `arozos_{platform}` and `web.tar.gz` from the [upstream releases](https://github.com/tobychui/arozos/releases)
2. Place both in the same directory
3. Run: `sudo ./arozos`

Visit `http://{host_ip}:8080/` to complete setup. Allow 3–5 minutes on first launch for file extraction.

### UI Access

```
Desktop: http://localhost:8080/desktop.system
Mobile:  http://localhost:8080/mobile.system
```

The mobile redirect is automatic based on user agent, but these URLs force a specific mode.

---

## Windows (amd64)

### Prerequisites

Install ffmpeg and add to PATH:
1. Download from https://www.ffmpeg.org/ to `C:\ffmpeg\`
2. Add `C:\ffmpeg\bin\` to System Environment Variables
3. Restart

### Install

1. Create a folder (ASCII name, no spaces)
2. Download `arozos_windows_amd64.exe` and `web.tar.gz` from releases
3. Place both in the folder
4. Double-click the exe
5. Allow firewall access if prompted
6. Visit `http://localhost:8080/`

Some features are unavailable on Windows. ARM64 Windows builds are experimental.

---

## Docker

```bash
docker build -t arozos .
docker run -p 8090:8080 arozos
```

The Dockerfile builds from source with a multi-stage build (Go builder → Debian slim runtime). Includes ffmpeg and ttyd.

For persistent data, mount the storage directories:

```bash
docker run -p 8090:8080 \
  -v /path/to/files:/arozos/files \
  -v /path/to/system:/arozos/system \
  arozos
```

---

## OpenWRT / RISC-V

Experimental. Download the appropriate binary from releases:

```bash
wget -O arozos {binary_url}
chmod +x ./arozos
sudo ./arozos
```

---

## Systemd Service

Create `/etc/systemd/system/arozos.service`:

```ini
[Unit]
Description=ArozOS Cloud Desktop Service

[Service]
Type=simple
WorkingDirectory=/home/pi/arozos/
ExecStart=/home/pi/arozos/arozos
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
```

Then:

```bash
sudo systemctl enable arozos.service
sudo systemctl start arozos.service
systemctl status arozos.service
```

---

## OTA Updates (Launcher)

The [ArozOS Launcher](https://github.com/aroz-online/launcher) handles over-the-air updates so you don't need SSH access for every update. Install it via the automated install script or manually.

---

## File Servers

ArozOS can share files through multiple protocols:

- **Share API**: Right-click a file in File Manager → Share
- **User Accounts**: Create accounts with permission-group-scoped storage access
- **Network File Servers**: Enable WebDAV, SFTP, or FTP in System Settings → Networks & Connections → File Servers
- **Legacy Browser Server**: Basic HTTP + Basic Auth for old devices. Enable in System Settings → Networks & Connections → File Servers → Directory Server. Login with ArozOS credentials.
