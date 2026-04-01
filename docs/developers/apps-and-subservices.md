# Apps and Subservices

ArozOS supports two types of applications. **Webapps** are static HTML/JS/CSS with optional server-side scripting via AGI. **Subservices** are external processes that ArozOS launches, manages, and reverse-proxies to. Both register as modules and appear in the desktop app launcher.

## Webapps

### Directory Structure

Create a folder under `src/web/`:

```
src/web/MyApp/
├── init.agi              # Registers the module on startup (required)
├── index.html            # Main page (opens in float window)
├── img/
│   ├── icon.png          # Module icon (64x64)
│   └── desktop_icon.png  # Desktop shortcut icon (128x128)
└── backend/
    └── api.js            # Server-side AGI scripts (optional)
```

ArozOS scans `web/*/init.agi` on startup. Without an `init.agi`, the folder is treated as static resources, not an app.

### init.agi

The start script registers your app with ArozOS:

```javascript
var moduleLaunchInfo = {
    Name: "My App",
    Desc: "Does a thing",
    Group: "Office",
    IconPath: "MyApp/img/icon.png",
    Version: "1.0",
    StartDir: "MyApp/index.html",
    SupportFW: true,
    LaunchFWDir: "MyApp/index.html",
    SupportEmb: true,
    LaunchEmb: "MyApp/embedded.html",
    InitFWSize: [800, 600],
    InitEmbSize: [400, 300],
    SupportedExt: [".txt", ".md"]
}

registerModule(JSON.stringify(moduleLaunchInfo));
```

### Module Info Fields

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| Name | string | ✓ | Display name in the app launcher |
| Desc | string | | Short description |
| Group | string | ✓ | Category in the start menu (see groups below) |
| IconPath | string | ✓ | Path to module icon, relative to web root. **Must include the module folder name** (e.g. `MyApp/img/icon.png`) |
| Version | string | ✓ | Version string |
| StartDir | string | ✓ | Default entry point. **Must include the module folder name.** For subservices, this also determines the reverse proxy path |
| SupportFW | bool | | Enable float window mode on the web desktop |
| LaunchFWDir | string | | Entry point for float window mode (falls back to StartDir) |
| SupportEmb | bool | | Enable embedded/file-open mode |
| LaunchEmb | string | | Entry point when opening a file with this app |
| InitFWSize | [int, int] | | Default float window size [width, height] |
| InitEmbSize | [int, int] | | Default embedded window size [width, height] |
| SupportedExt | string[] | | File extensions this app can open (e.g. `[".mp3", ".flac"]`) |

Setting `StartDir` to an empty string hides the app from the start menu. Use this for file-open-only apps (like a PDF viewer) that have no standalone interface.

### Webapp Groups

| Group | Description | Reserved |
|-------|-------------|----------|
| Media | Media playback apps | No |
| Office | Text editing, office tools | No |
| Download | Download utilities | No |
| Files | File/storage management | No |
| Internet | Network, proxy, browser tools | No |
| Settings | Third-party settings tools | No |
| System Tools | Preinstalled system tools | Yes |
| Utilities | Accessible by all users regardless of permission settings | Yes |
| Interface Module | Custom landing interfaces (POS, kiosk) | Yes |
| IME | Input method editors | Yes |
| Development | Dev/debug tools for ArozOS itself | Yes |

Any other group string appears under "Others" in the start menu.

### Launch Modes

| Mode | When used | Field |
|------|-----------|-------|
| Default | Standard browser or PWA | StartDir |
| Float Window | Web desktop environment | LaunchFWDir |
| Embedded | Opening a file with this app | LaunchEmb |

If LaunchFWDir is not set, StartDir is used as fallback. Embedded mode passes file info as a URL hash — decode it with `ao_module_loadInputFiles()` (see [Frontend API](frontend-api.md)).

### Frontend-Backend Interaction

Include `ao_module.js` (which requires jQuery) in your HTML:

```html
<script src="../script/jquery.min.js"></script>
<script src="../script/ao_module.js"></script>
```

**Always use relative paths** for these imports. Absolute paths break the internal path resolution.

Call a backend AGI script:

```javascript
ao_module_agirun("MyApp/backend/api.js", {
    name: "Neon"
}, function(resp) {
    console.log(resp);
}, function() {
    console.log("Request failed");
}, 3000);  // timeout in ms (optional)
```

The backend script receives parameters as global variables:

```javascript
// MyApp/backend/api.js
if (typeof(name) != "undefined") {
    sendResp("Hello " + name);
} else {
    sendResp("Hello there");
}
```

For complex payloads, POST JSON to the AGI endpoint directly:

```javascript
fetch(ao_root + "system/ajgi/interface?script=MyApp/backend/api.js", {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ foo: 'bar' })
}).then(r => r.json()).then(data => console.log(data));
```

In the backend, access the JSON payload via `POST_data`:

```javascript
let payload = POST_data;
console.log(payload.foo);  // "bar"
```

For the complete AGI API (filelib, http, websocket, imagelib, etc.), see [AGI Reference](agi-reference.md).

For float window control, file selectors, and other frontend APIs, see [Frontend API](frontend-api.md).

### init.agi Limitations

The init.agi script runs at startup with system scope. Only standard library and `appdata` functions are available — user functions like `filelib` are not usable in start scripts.

---

## Subservices

Subservices are external processes managed by ArozOS. They can be written in any language. ArozOS assigns them a port, launches them, and creates a reverse proxy so they're accessible through the main ArozOS URL.

### Directory Structure

```
src/subservice/MyService/
├── moduleInfo.json         # Module metadata (required)
├── .startscript            # Flag: use start.sh instead of a binary
├── .noproxy                # Flag: don't create a reverse proxy
├── .disabled               # Flag: skip this subservice on startup
├── .intport                # Flag: pass port as "12810" instead of ":12810"
├── start.sh                # Launch script (if .startscript flag is set)
└── MyService_linux_arm64   # Binary (if no .startscript flag)
```

### moduleInfo.json

Same structure as the webapp module info, but stored as JSON:

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

Alternatively, the binary can output this JSON when called with `-info`.

### Startup Protocol

ArozOS launches each subservice with two flags:

```
./MyService -port :12810 -rpt http://localhost:8080/api/ajgi/interface
```

- `-port` — the port to listen on (prefixed with `:` unless `.intport` flag exists)
- `-rpt` — the AGI gateway callback URL for accessing ArozOS APIs from the subservice

### Reverse Proxy Mechanism

`filepath.Dir(StartDir)` becomes the proxy endpoint. For `StartDir: "MyService/"`, any request to `/MyService/*` is forwarded to `localhost:PORT`.

ArozOS injects these headers into proxied requests:
- `aouser` — the authenticated username
- `aotoken` — the session token

WebSocket connections are proxied automatically (the `Upgrade: websocket` header is detected and handled).

### start.sh

When `.startscript` is present, ArozOS runs `start.sh` (or `start.bat` on Windows) instead of looking for a binary. The script receives the same `-port` and `-rpt` flags:

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

### Binary Naming Convention

Without `.startscript`, ArozOS looks for a binary matching the platform:

| Platform | Binary name |
|----------|------------|
| Linux AMD64 | `MyService_linux_amd64` |
| Linux ARM64 | `MyService_linux_arm64` |
| Linux ARMv6/v7 | `MyService_linux_arm` |
| macOS AMD64 | `MyService_macOS_amd64` |
| Windows | `MyService.exe` |

On Linux, ArozOS also checks `which MyService` for system-installed packages before looking for the binary in the subservice directory.

### Exec Setting Flags

| Flag file | Effect |
|-----------|--------|
| `.startscript` | Use `start.sh`/`start.bat` instead of the binary |
| `.noproxy` | Launch the process but don't create a reverse proxy (compatibility mode) |
| `.disabled` | Skip this subservice on startup (can be re-enabled via the settings UI) |
| `.intport` | Pass port as `12810` instead of `:12810` |

### Accessing AGI from a Subservice Backend

Subservices can call back into ArozOS's AGI gateway using the `-rpt` URL. Here's a Go example:

```go
package main

import (
    aroz "your/package/name/aroz"
)

var handler *aroz.ArozHandler

func main() {
    handler = aroz.HandleFlagParse(aroz.ServiceInfo{
        Name:         "My Service",
        Desc:         "Example subservice",
        Group:        "Development",
        IconPath:     "MyService/icon.png",
        Version:      "0.0.1",
        StartDir:     "MyService/home.html",
        SupportFW:    true,
        LaunchFWDir:  "MyService/home.html",
        SupportEmb:   false,
        LaunchEmb:    "",
        InitFWSize:   []int{720, 480},
        InitEmbSize:  []int{720, 480},
        SupportedExt: []string{},
    })

    http.ListenAndServe(handler.Port, nil)
}

func apiHandler(w http.ResponseWriter, r *http.Request) {
    username, token := handler.GetUserInfoFromRequest(w, r)

    script := `
        if (requirelib("filelib")) {
            var files = filelib.glob("user:/Desktop/*");
            sendJSONResp(JSON.stringify(files));
        }
    `

    resp, err := handler.RequestGatewayInterface(token, script)
    if err != nil {
        http.Error(w, err.Error(), 500)
        return
    }
    defer resp.Body.Close()

    body, _ := io.ReadAll(resp.Body)
    w.Header().Set("Content-Type", "application/json")
    w.Write(body)
}
```

---

## Hybrid Apps

A subservice can handle the backend while a webapp provides a custom frontend. This is useful when you want to wrap an existing tool but add ArozOS-specific UI on top.

The Terminal app is a working example:

- **Subservice** (`src/subservice/Terminal/`): runs ttyd, proxied at `/Terminal/*`
- **Webapp** (`src/web/WebTerminal/`): static HTML wrapper with a mobile touch toolbar, embeds ttyd in an iframe

The key is splitting `StartDir` and `LaunchFWDir` in `moduleInfo.json`:

```json
{
    "StartDir": "Terminal/",
    "LaunchFWDir": "WebTerminal/index.html"
}
```

`StartDir` sets up the reverse proxy at `/Terminal/*`. `LaunchFWDir` is what the user actually sees when they click the app — the wrapper page at `/WebTerminal/`. This separation keeps the proxy routing and the user-facing UI independent.

See `src/web/WebTerminal/DEVELOPER.md` for the full Terminal implementation reference.

---

## Important Constraints

### Icon paths vs. proxy paths

Icons are served by ArozOS's static file server. Requests under a subservice proxy endpoint (e.g. `/Terminal/*`) are forwarded to the subservice, not served as static files. If your icon is at `Terminal/img/icon.png`, it'll 404 because ttyd doesn't know about it.

**Rule:** place subservice icons outside the proxy path. We use `img/subservice/` for this.

### Path prefix collisions

The subservice proxy uses a prefix match: `requestURL[1:len(endpoint)+1] == endpoint`. A subservice at `Terminal/` intercepts `/TerminalApp/`, `/TerminalFoo/`, etc. — any path whose first N characters match.

**Rule:** name webapp directories so they don't start with any subservice proxy endpoint.

### Don't double-register

If a subservice has a `moduleInfo.json` and you also create an `init.agi` in a webapp folder that registers the same module, you'll get duplicate entries in the app launcher. Use one or the other. For hybrid apps, let `moduleInfo.json` handle registration.

### Transparent backgrounds

Float windows have transparent backgrounds by default. If your webapp doesn't set `background-color` on `body`, the window will be see-through. Always set a solid background color in your CSS.
