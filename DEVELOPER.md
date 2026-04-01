# Developer Guide

This guide covers building, running, and developing apps for this ArozOS fork. For AI agent-specific instructions, see `AGENTS.md`.

## Quick Start

### Prerequisites

- Go 1.22+ (for building ArozOS)
- ttyd (`apt install ttyd`) — required for the Terminal subservice

### Build and Run

```bash
# Clone
git clone git@github.com:neonspectra/monika-aroz.git
cd monika-aroz

# Build
cd src && go build -o ../arozos && cd ..

# Create symlinks for local development
ln -sf src/web web
ln -sf src/system system
ln -sf src/subservice subservice

# Run on port 8090
./arozos -port 8090
```

On first launch, navigate to `http://localhost:8090` and create an admin user.

### Docker

```bash
docker build -t arozos .
docker run -p 8090:8080 arozos
```

## How ArozOS Apps Work

ArozOS has two app types. Both register as modules and appear in the desktop app launcher.

### Webapps

Static HTML/JS/CSS in `src/web/YourApp/`. The simplest way to add functionality.

**Minimal webapp structure:**
```
src/web/MyApp/
├── init.agi          # Registers the module on startup
├── index.html        # Main page (opens in float window)
├── img/
│   └── icon.png      # App icon
└── backend/
    └── api.js        # Optional: server-side AGI scripts
```

**init.agi** — registers the app:
```javascript
var moduleLaunchInfo = {
    Name: "My App",
    Desc: "Does a thing",
    Group: "Utilities",
    IconPath: "MyApp/img/icon.png",
    Version: "1.0",
    StartDir: "MyApp/index.html",
    SupportFW: true,
    LaunchFWDir: "MyApp/index.html",
    SupportEmb: false,
    LaunchEmb: "MyApp/index.html",
    InitFWSize: [800, 600],
    InitEmbSize: [400, 300],
    SupportedExt: []
}
registerModule(JSON.stringify(moduleLaunchInfo));
```

**Calling backend scripts from frontend:**
```javascript
// In your HTML, include ao_module.js first:
// <script src="../script/ao_module.js"></script>

ao_module_agirun("MyApp/backend/api.js", {
    param1: "value1"
}, function(data) {
    console.log(data);
});
```

**Backend AGI script** (`backend/api.js`):
```javascript
// Access GET/POST parameters
var value = param1;  // AGI exposes parameters as global variables

// Use libraries
if (requirelib("filelib")) {
    var files = filelib.readdir("user:/Desktop/");
    sendJSONResp(JSON.stringify(files));
}
```

### Subservices

External processes that ArozOS launches, manages, and reverse-proxies to. Use subservices when you need to wrap an existing tool or run a non-JS backend.

**Subservice structure:**
```
src/subservice/MyService/
├── moduleInfo.json     # Module metadata (required)
├── .startscript        # Flag: use start.sh instead of a binary
└── start.sh            # Launch script
```

**moduleInfo.json:**
```json
{
    "Name": "My Service",
    "Desc": "Does a thing",
    "Group": "System",
    "IconPath": "img/subservice/myservice.png",
    "Version": "1.0",
    "StartDir": "MyService/",
    "SupportFW": true,
    "LaunchFWDir": "MyService/",
    "SupportEmb": false,
    "LaunchEmb": "MyService/",
    "InitFWSize": [800, 500],
    "InitEmbSize": [800, 500],
    "SupportedExt": []
}
```

**start.sh** — ArozOS passes `-port :XXXX` and `-rpt <callback_url>`:
```bash
#!/bin/bash
PORT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        -port) PORT="${2#:}"; shift 2 ;;
        -rpt) shift 2 ;;
        *) shift ;;
    esac
done
exec my-tool --port "$PORT"
```

**How the reverse proxy works:**

`filepath.Dir(StartDir)` becomes the proxy endpoint. For `StartDir: "MyService/"`, any request to `/MyService/*` is forwarded to `localhost:PORT`. WebSocket connections are proxied automatically.

ArozOS injects `aouser` and `aotoken` headers into proxied requests so your service can identify the authenticated user.

### Hybrid Apps

You can combine both: a subservice for the backend and a webapp for a custom frontend. This is how the Terminal app works — ttyd runs as a subservice at `/Terminal/*`, and a static wrapper page at `/WebTerminal/` adds a mobile toolbar.

When doing this, use `LaunchFWDir` in the subservice's `moduleInfo.json` to point to the webapp page, while `StartDir` controls the proxy path.

## Important Constraints

### Icon paths

Icons are resolved relative to the web root and served by ArozOS's static file server. An icon path under a subservice proxy endpoint (e.g., `Terminal/img/icon.png`) will be caught by the reverse proxy and never served. Place icons outside proxy paths — we use `img/subservice/` for this.

### Path prefix collisions

The subservice proxy uses a prefix match. A subservice at `Terminal/` will intercept requests to `/TerminalApp/`, `/TerminalFoo/`, etc. Name your webapp directories so they don't start with any subservice endpoint.

### Module registration

Don't register the same app in both `init.agi` and `moduleInfo.json` — it creates duplicate entries in the launcher. Use one or the other. For hybrid apps, let the subservice `moduleInfo.json` handle registration and point `LaunchFWDir` to the webapp.

## AGI Libraries

Server-side scripts can load libraries with `requirelib("name")`. The main ones:

| Library | Purpose |
|---------|---------|
| `filelib` | Filesystem: read, write, delete, glob, mkdir, stat |
| `http` | HTTP client: GET, POST, HEAD, download |
| `websocket` | Upgrade to WebSocket for real-time communication |
| `imagelib` | Image resize, crop, dimension, classification |
| `appdata` | Read-only access to files in the web directory |
| `iot` | IoT device discovery and control |
| `share` | File sharing with UUID-based links |

See `src/agi-doc.md` for the complete API reference.

## Existing Apps to Reference

- **Music** (`src/web/Music/`) — good example of AGI backend calls from frontend
- **UnitTest** (`src/web/UnitTest/`) — test scripts for AGI features, including WebSocket
- **Terminal** (`src/web/WebTerminal/`) — hybrid subservice + webapp, see `DEVELOPER.md` in that directory
