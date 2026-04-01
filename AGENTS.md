# AGENTS.md — AI Agent Development Guide

This file contains instructions and context for AI coding agents working on this repository. If you're a human developer, see `DEVELOPER.md` for the quickstart guide.

## Repository Structure

This is a fork of [ArozOS](https://github.com/tobychui/arozos) — a web-based desktop operating system written in Go. The upstream remote is `upstream` (tobychui/arozos); our fork is `origin` (neonspectra/monika-aroz).

```
src/                    Go source + web assets (the actual ArozOS codebase)
  ├── web/              Static webapps served by ArozOS's file server
  │   ├── WebTerminal/  Terminal wrapper app (our addition)
  │   ├── Music/        Example: built-in webapp with AGI backend
  │   └── ...
  ├── subservice/       Subservice directories (our additions, un-gitignored in this fork)
  │   └── Terminal/     ttyd subservice
  ├── mod/              Go modules (subservice router, file servers, etc.)
  ├── system/           System config templates
  ├── agi-doc.md        AGI scripting API reference
  └── *.go              Core ArozOS Go source
Dockerfile              Container build
```

## Building and Running Locally

```bash
cd src && go build -o ../arozos && cd ..
ln -sf src/web web
ln -sf src/system system
ln -sf src/subservice subservice
./arozos -port 8090
```

First run creates an admin user via the web UI. After that, login credentials persist in `system/ao.db`.

**Killing the process:** ArozOS spawns child processes for subservices. Always kill both:
```bash
pkill -9 -f arozos; pkill -9 -f "ttyd.*12810"
```
Orphaned subservice processes bind ports and block restarts. Check with `lsof -i :12810` if a subservice won't start.

## Testing Changes

- **Go source changes** (`src/*.go`, `src/mod/**`): requires rebuilding the binary.
- **Web assets** (`src/web/**`): takes effect on page reload (served as static files via symlink).
- **Subservice scripts** (`src/subservice/**/start.sh`): requires restarting ArozOS (subservices launch on startup).
- **Subservice moduleInfo.json**: requires restarting ArozOS (read once at launch).

### Browser Testing

ArozOS has two UIs:
- **Desktop** (`desktop.html`): float windows, loaded when `navigator.userAgent` doesn't match mobile patterns.
- **Mobile** (`mobile.html`): redirected automatically when UA matches `/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i`.

Firefox responsive mode does NOT change the user agent. To test mobile, either:
- Navigate directly to `http://localhost:8090/mobile.html`
- Use a real device on the same network

To test touch-only features (like the terminal toolbar), inject this in the console before loading:
```js
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: query => ({
    matches: query === '(any-pointer: coarse)' ? true : window.matchMedia(query).matches,
    media: query, onchange: null,
    addListener: () => {}, removeListener: () => {},
    addEventListener: () => {}, removeEventListener: () => {},
    dispatchEvent: () => {},
  })
});
```

## Key Architecture Concepts

### Request Routing (main.router.go)

All requests flow through `mrouter`. The priority order:
1. Public paths (`/favicon.ico`, `/img/public/*`, `/script/*`) — no auth
2. Login/reset pages — special handling
3. WebDAV, share, serverless (`/api/remote/`) — their own routers
4. **Authenticated paths** — everything else requires login, then:
   a. Check subservice reverse proxy first (`ssRouter.CheckIfReverseProxyPath`)
   b. If not a subservice path, serve static files from `web/`

**Critical implication:** subservice proxy paths take priority over static files. A static file at `web/Terminal/anything.html` will never be served because `/Terminal/*` is intercepted by the reverse proxy. This is why our Terminal wrapper lives at `web/WebTerminal/` instead.

### Subservice Proxy Path Matching

The proxy check in `CheckIfReverseProxyPath` is a **prefix match**:
```go
requestURL[1:len(thisServiceProxyEP)+1] == thisServiceProxyEP
```

A subservice with `StartDir: "Terminal/"` creates proxy endpoint `"Terminal"`. This catches `/Terminal/`, `/Terminal/foo`, and also `/TerminalApp/foo` — any path whose first N characters match. Choose webapp directory names that don't start with any subservice endpoint prefix.

### Two Ways to Build Apps

**1. Webapps (AGI):** Static HTML/JS/CSS in `src/web/YourApp/` with an `init.agi` script for module registration and optional server-side JS via the AGI gateway. No compilation needed. Frontend calls backend via `ao_module_agirun()` or direct AJAX to `/system/ajgi/interface?script=YourApp/backend/foo.js`.

**2. Subservices:** External processes in `src/subservice/YourService/`. ArozOS launches them, assigns a port, and reverse-proxies to them. Can be any language — Go binaries, shell scripts wrapping existing tools, etc. Registered via `moduleInfo.json`. Use `.startscript` flag + `start.sh` for non-binary launchers.

The Terminal app uses both: a subservice (ttyd) for the backend, and a webapp (WebTerminal) for the frontend wrapper.

### ModuleInfo Fields That Matter

```
StartDir      — For webapps: the default page. For subservices: determines the reverse proxy path.
                filepath.Dir(StartDir) becomes the proxy endpoint.
LaunchFWDir   — What actually opens in the float window. Can differ from StartDir.
IconPath      — Relative to web root. Must NOT be under a subservice proxy path.
SupportFW     — Must be true for the app to appear in the desktop app launcher.
```

### AGI Capabilities (Quick Reference)

Server-side JavaScript executed via the AGI gateway. Key libraries:
- `filelib` — filesystem operations (read, write, glob, mkdir)
- `http` — make GET/POST/HEAD requests to external services
- `websocket` — upgrade HTTP to WebSocket for real-time communication
- `imagelib` — resize, crop, classify images
- `appdata` — read-only access to files in the web directory
- `iot` — IoT device control
- `share` — file sharing with UUID-based links

See `src/agi-doc.md` for the full API reference.

### ao_module.js (Frontend API)

The standard client-side library at `web/script/ao_module.js`. Key functions:
- `ao_module_agirun(script, params, callback)` — call an AGI backend script
- `ao_module_close()` — close the current float window
- `ao_module_setWindowTitle(title)` — update float window title

## Gotchas for Agents

- **Symlinks are required for local dev.** Without `web`, `system`, and `subservice` symlinks at the repo root, ArozOS can't find its assets.
- **The `.gitignore` matters.** `src/subservice/*` was un-gitignored in this fork. Runtime data directories (`/files/`, `/tmp/`, database files) are gitignored. Check before committing.
- **Orphaned processes.** Always kill subservice children when stopping ArozOS. `pkill -f arozos` alone may leave ttyd (or future subservices) bound to ports.
- **Port 12810** is the base port for subservices. ArozOS auto-assigns incrementally from there.
- **ArozOS auto-restarts crashed subservices** after 10 seconds. If you kill a subservice to restart it, the old one may come back as a zombie. Kill ArozOS and all children for a clean slate.
- **Static files under subservice proxy paths are unreachable.** Icons, docs, or any asset under a path prefix that matches a subservice endpoint will be proxied, not served.
- **The Parallels shared filesystem** (`/media/psf/`) can cause issues with background process management and log file truncation. Use `nohup` or `disown` for long-running processes, and prefer `> newfile.log` over truncating existing log files.
