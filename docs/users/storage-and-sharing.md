# Storage and File Sharing

## Storage Pools

ArozOS uses storage pools to manage where files are stored. Each pool maps a virtual path ID to a physical or remote storage location. Configure pools via **System Settings → Disk & Storage → Storage Pools**.

### Pool Properties

| Property | Description | Example |
|----------|-------------|---------|
| Name | Display name | "Movie Storage" |
| UUID | Unique ID (ASCII, no spaces) — becomes the virtual path prefix | "movie" (accessed as `movie:/`) |
| Path | Mount path or protocol URL (see below) | `/media/storage1` |
| Access Permission | Read Only or Read Write | |
| Storage Hierarchy | How users see each other's files (see below) | |
| File System Type | Disk format or protocol | |

### Storage Hierarchy

- **Isolated User Folder** — each user has a private directory within the pool. Users cannot see each other's files.
- **Public Access Folders** — all users share the same directory. If permission is Read Write, any user can modify any file.

### Supported Storage Types

#### Local Disk

Mount any local filesystem (ext4, NTFS, FAT, etc.) by specifying the mount path on the host OS.

| Property | Example |
|----------|---------|
| Path | `/media/storage1` |
| Mount Device | `/dev/sda1` |
| Mount Point | `/media/storage` |
| Automount | Yes/No |

Automount tells ArozOS to mount the disk on startup. For disks required by the `-root` flag, use `/etc/fstab` instead — ArozOS's automount is designed for non-essential storage to reduce power spikes during startup.

#### WebDAV

| Property | Example |
|----------|---------|
| Path | `https://example.com/webdav/storage` |
| Username | your WebDAV username |
| Password | your WebDAV password |

#### FTP / SFTP

| Property | Example |
|----------|---------|
| Path | `192.168.1.220:2022` |
| Username | your FTP/SFTP username |
| Password | your FTP/SFTP password |

#### SMB (Windows File Sharing)

| Property | Example |
|----------|---------|
| Path | `192.168.0.110/MyShare` |
| Username | your SMB username |
| Password | your SMB password |

The share name (`MyShare`) should match one of the shares visible when browsing `\\192.168.0.110` in Windows File Explorer.

---

## File Sharing

ArozOS includes a sharing system similar to Google Drive. Right-click any file in File Manager and select **Share** to generate a UUID-based link.

### Share Options

- **Timeout** — how long the share link remains active. Set to 0 for permanent shares.
- **Permission** — who can access the share:
  - `anyone` — accessible without login
  - `signedin` — requires an ArozOS account
  - `samegroup` — requires an account in the same permission group as the sharer

Share links follow the format: `http://your-host:port/share/{uuid}`

Note: share timeouts are tracked in memory. If ArozOS restarts before a timeout expires, the share will persist (it won't be automatically removed after restart).

---

## Network File Servers

For sharing files with external devices and applications, ArozOS can run standard file server protocols. Configure these in **System Settings → Networks & Connections → File Servers**.

### WebDAV

Exposes user files over the WebDAV protocol. Accessible from:
- Windows Explorer (Map Network Drive)
- macOS Finder (Connect to Server)
- Mobile file managers (e.g. Solid Explorer, Documents by Readdle)
- Any WebDAV client

Access at: `http://your-host:port/webdav/`

Login with your ArozOS credentials.

### SFTP

Secure file transfer over SSH. Requires an SSH-capable client (e.g. FileZilla, WinSCP, `sftp` command).

### FTP

Legacy file transfer protocol. Use only on trusted networks — FTP transmits credentials in plain text.

### Directory Server (Legacy Browser)

A basic HTTP file listing with Basic Auth authentication. Designed for old devices with outdated browsers that can't run the full ArozOS web interface. Enable in System Settings → Networks & Connections → File Servers → Directory Server.

Login with your ArozOS credentials.
