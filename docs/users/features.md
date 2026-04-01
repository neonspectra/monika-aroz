# Features

## Web Desktop Interface

ArozOS provides a full desktop environment in the browser with float windows, a start menu, taskbar, and drag-and-drop file management. It works on both desktop and mobile browsers, with a responsive mobile UI that automatically activates on phones and tablets.

- Floating window system with resize, minimize, maximize, and drag
- Start menu with categorized app launcher
- Desktop shortcuts and wallpaper customization
- Progressive Web App (PWA) support for mobile home screen installation
- Touch-optimized mobile interface with sidebar navigation

## Bundled Applications

### Productivity
- **NotepadA** — Code editor with syntax highlighting (powered by Ace editor). Supports a wide range of file types including JavaScript, Go, Python, HTML, CSS, Markdown, and more.
- **MDEditor** — Markdown editor with live preview
- **OfficeViewer** — Viewer for Microsoft Office documents (Word, Excel, PowerPoint)
- **PDF Viewer** — In-browser PDF reader
- **Code Studio** — IDE-style code editor (powered by Monaco, the same editor engine as VS Code)
- **Memo** — Quick notes and sticky notes

### Media
- **Music** — Audio player with playlist support. Plays MP3, FLAC, WAV, OGG, AAC, and WebM.
- **Video** — Video player with in-browser playback and real-time transcoding for unsupported formats (requires ffmpeg)
- **Photo** — Image viewer with slideshow mode
- **Paint** — Simple drawing and image annotation tool
- **Camera** — Webcam capture (on supported devices)
- **Recorder** — Audio recording from microphone

### Utilities
- **Browser** — Embedded web browser
- **Clock** — World clock display
- **Timer** — Countdown timer and stopwatch
- **Speedtest** — Network speed testing
- **Web Builder** — Simple HTML page builder
- **Web Downloader** — Download files from URLs to your ArozOS storage
- **Manga** — Comic/manga reader for image archives
- **OnScreenKeyboard** — Virtual keyboard for touch devices without hardware keyboards

### System
- **File Manager** — Full-featured file browser with drag-and-drop upload, cut/copy/paste, rename, sharing, and multi-file operations with progress tracking
- **System Settings** — User management, storage pools, network configuration, module permissions, and system information
- **Management Gateway** — Alternative settings interface for non-desktop environments
- **Serverless** — Create and manage AGI script endpoints for webhooks and automation
- **Terminal** *(this fork)* — Web-based shell via ttyd with mobile touch toolbar

## File and Disk Management

- **Virtual filesystem** with sandboxed user directories. Each user sees their own `user:/` root.
- **Multiple storage backends** — mount local disks (ext4, NTFS, FAT), or connect to remote storage via WebDAV, SMB, SFTP, and FTP
- **Storage pools** — configure multiple storage locations with per-user or shared access, read-only or read-write permissions
- **File sharing** — share files via UUID-based links with optional expiration, similar to Google Drive sharing
- **File versioning** — automatic version history for edited files
- **Drag-and-drop upload** with real-time progress
- **WebSocket chunked upload** for large files on low-memory devices

## Network File Servers

ArozOS can expose files through standard network protocols:

- **WebDAV** — accessible from any WebDAV client (including Windows Explorer, macOS Finder, and mobile file managers)
- **SFTP** — secure file transfer over SSH
- **FTP** — legacy file transfer protocol
- **Directory Server** — basic HTTP file listing with Basic Auth, designed for legacy devices with outdated browsers

All file servers authenticate against ArozOS user accounts and respect permission group settings.

## Networking

- **mDNS discovery** — ArozOS instances can find each other on the local network
- **SSDP broadcast** — appear in Windows Network Neighborhood
- **UPnP port forwarding** — automatic router configuration for external access
- **Cluster support** — discover and link multiple ArozOS instances on LAN
- **WiFi management** — configure wireless connections on Raspberry Pi (wpa_supplicant) and Armbian (nmcli)
- **Static web server** — host static sites with the built-in web editor

## Security

- **Session-based authentication** with configurable session keys (AES-128/192/256)
- **oAuth** integration
- **LDAP** directory authentication
- **IP whitelist/blacklist** — restrict access by IP address
- **Exponential login timeout** — progressive lockout on failed attempts
- **Per-user permission groups** — control which apps and storage pools each user can access
- **Public registration** toggle — optionally allow self-service account creation

## IoT

- **Device discovery** — scan for and connect to IoT devices on the network
- **Control endpoints** — interact with smart devices (e.g. Sonoff switches) through a unified interface
- **Scriptable via AGI** — automate IoT actions with the `iot` library in backend scripts

## Extensibility

- **AGI scripting** — server-side JavaScript for building custom backends without compiling Go
- **Subservice architecture** — integrate any external web application as a managed, reverse-proxied module
- **WebSocket support** — real-time bidirectional communication for interactive apps
- **Scheduled tasks** — run AGI scripts on intervals for automation
- **Serverless endpoints** — expose AGI scripts as API endpoints for webhooks and external integrations

## Platform Support

- **Linux** — primary platform. Supports amd64, arm64, armv6/v7 (Raspberry Pi, Orange Pi, etc.)
- **Windows** — amd64 supported, arm64 experimental. Some features unavailable.
- **macOS** — amd64 supported
- **Docker** — multi-stage Dockerfile included in this fork
- **Minimum requirements** — 512MB RAM, 1.5GB storage
