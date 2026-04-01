# Configuration

## Startup Flags

ArozOS accepts the following command-line flags:

### Core

| Flag | Default | Description |
|------|---------|-------------|
| `-port` | 8080 | HTTP listening port |
| `-hostname` | "My ArOZ" | Display name for this host |
| `-root` | "./files/" | User root directory |
| `-console` | false | Enable debugging console |
| `-demo_mode` | false | Read-only mode for all directories and databases |
| `-version` | | Print build version and exit |

### TLS / HTTPS

| Flag | Default | Description |
|------|---------|-------------|
| `-tls` | false | Enable HTTPS |
| `-tls_port` | 8443 | HTTPS listening port |
| `-cert` | "localhost.crt" | TLS certificate path |
| `-key` | "localhost.key" | TLS key path |
| `-disable_http` | false | Disable HTTP (requires `-tls=true`) |

### Storage and Upload

| Flag | Default | Description |
|------|---------|-------------|
| `-max_upload_size` | 8192 | Max upload size in MB |
| `-upload_buf` | 25 | Upload buffer in MB (files larger than this buffer to disk) |
| `-upload_async` | false | Async upload buffering (requires ≥8GB RAM) |
| `-tmp` | "./" | Temporary storage path (recommend SSD) |
| `-tmp_time` | 86400 | Temp file TTL in seconds (default 24h) |
| `-storage_config` | "./system/storage.json" | Storage pool config file path |
| `-bufffile_size` | 25 | Max buffer file size in MB for filesystem abstractions |
| `-buffpool_size` | 1024 | Max buffer pool size in MB |
| `-enable_buffpool` | true | Enable buffer pool |

### Networking and Discovery

| Flag | Default | Description |
|------|---------|-------------|
| `-allow_mdns` | true | Enable mDNS discovery |
| `-allow_ssdp` | true | Enable SSDP (Windows Network Neighborhood) |
| `-allow_upnp` | false | Enable UPnP port forwarding |
| `-allow_cluster` | true | Enable LAN cluster operations (requires mDNS) |
| `-disable_ip_resolver` | false | Disable IP resolving (for reverse proxy environments) |
| `-force_mac` | | Force a specific MAC address for discovery |

### Features

| Flag | Default | Description |
|------|---------|-------------|
| `-allow_iot` | true | Enable IoT APIs and scanner |
| `-allow_pkg_install` | true | Allow apt package installation |
| `-enable_hwman` | true | Enable hardware management |
| `-enable_pwman` | true | Enable power management |
| `-homepage` | true | Enable user homepages at `/www/{username}/` |
| `-dir_list` | true | Enable directory listing |
| `-gzip` | true | Enable gzip compression |
| `-disable_subservice` | false | Disable all subservices |
| `-allow_autologin` | true | Allow RESTful login redirection |
| `-public_reg` | false | Enable public account registration |

### WiFi (Raspberry Pi / Armbian)

| Flag | Default | Description |
|------|---------|-------------|
| `-wlan_interface_name` | "wlan0" | Default wireless interface |
| `-wpa_supplicant_config` | "/etc/wpa_supplicant/wpa_supplicant.conf" | wpa_supplicant config path |

### Scheduling

| Flag | Default | Description |
|------|---------|-------------|
| `-ntt` | 3 | Nightly task execution hour (24h format) |

### Session

| Flag | Default | Description |
|------|---------|-------------|
| `-session_key` | (auto) | Session key, must be 16/24/32 bytes (AES-128/192/256) |
| `-logging` | true | Enable logging to file |
| `-iobuf` | 1024 | IO buffer size in bytes |

### Examples

```bash
# Standard web port
./arozos -port 80

# Demo mode
./arozos -demo_mode=true

# HTTPS only
./arozos -tls=true -tls_port 443 -key mykey.key -cert mycert.crt -disable_http=true

# Both HTTP and HTTPS
./arozos -port 80 -tls=true -key mykey.key -cert mycert.crt -tls_port 443

# Limit upload to 25MB
./arozos -max_upload_size 25
```

---

## Storage Pools

Configure via System Settings → Disk & Storage → Storage Pools, or edit `system/storage.json` directly.

Each storage pool entry requires:

| Field | Description | Example |
|-------|-------------|---------|
| Name | Display name | "Movie Storage" |
| UUID | Unique ID (ASCII, no spaces) | "movie" |
| Path | Mount path or protocol URL | See below |
| Access Permission | Read Only or Read Write | |
| Storage Hierarchy | Isolated (per-user) or Public | |
| File System Type | Disk format or protocol | |

### Path formats by storage type

| Type | Path format | Example |
|------|------------|---------|
| Local disk | Mount path on host | `/media/storage1` |
| WebDAV | URL | `https://example.com/webdav/storage` |
| FTP / SFTP | IP:port | `192.168.1.220:2022` |
| SMB | IP/share | `192.168.0.110/MyShare` |

Local disk additional options: Mount Device (`/dev/sda1`), Mount Point (`/media/storage`), Automount toggle.

---

## Vendor Customization

Create a `vendor-res/` directory in the ArozOS root and place replacement files:

| Filename | Size | Purpose |
|----------|------|---------|
| `auth_bg.jpg` | 2938 × 1653 | Login page wallpaper |
| `auth_icon.png` | 5900 × 1180 | Authentication page logo |
| `vendor_icon.png` | 1560 × 600 | Vendor brand icon |
