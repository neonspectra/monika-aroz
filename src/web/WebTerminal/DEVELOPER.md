# Terminal App — Developer Reference

## Overview

The Terminal app provides a web-based shell accessible through the ArozOS desktop and mobile UI. It combines two components: a **ttyd subservice** that runs the actual terminal backend, and a **WebTerminal webapp** that wraps it with a mobile-friendly touch toolbar.

On desktop, the user gets raw ttyd (xterm.js in the browser, WebSocket to a pty). On mobile, the wrapper adds a toolbar with keys that touch keyboards lack: Tab, Ctrl-C, Esc, arrow keys, and more.

## Architecture

```
┌─────────────────────────────────────────────┐
│  ArozOS                                     │
│                                             │
│  ┌──────────────────────┐                   │
│  │  Float Window        │                   │
│  │  (iframe)            │                   │
│  │                      │                   │
│  │  ┌────────────────┐  │                   │
│  │  │ WebTerminal/   │  │  Static file      │
│  │  │ index.html     │──┼──served by ArozOS │
│  │  │                │  │                   │
│  │  │  ┌──────────┐  │  │                   │
│  │  │  │ iframe   │  │  │                   │
│  │  │  │/Terminal/ │──┼──┼── Reverse proxy   │
│  │  │  │ (ttyd)   │  │  │   to localhost:N  │
│  │  │  └──────────┘  │  │                   │
│  │  │  ┌──────────┐  │  │                   │
│  │  │  │ Toolbar  │  │  │  Touch devices    │
│  │  │  │ (buttons)│  │  │  only             │
│  │  │  └──────────┘  │  │                   │
│  │  └────────────────┘  │                   │
│  └──────────────────────┘                   │
│                                             │
│  Subservice: ttyd                           │
│  Port: auto-assigned (base 12810)           │
│  Process: ttyd -W -t disableReconnect=true  │
│           -w ~ -p PORT /bin/bash            │
└─────────────────────────────────────────────┘
```

## File Layout

```
subservice/Terminal/
├── .startscript          # Tells ArozOS to use start.sh instead of a binary
├── start.sh              # Parses ArozOS args, launches ttyd
├── moduleInfo.json       # Module metadata (name, icon, launch URLs)
└── img/
    └── icon.png          # App icon (not used directly — see gotcha below)

src/web/WebTerminal/
└── index.html            # Wrapper page with iframe + touch toolbar

src/web/img/subservice/
└── terminal.png          # App icon served by ArozOS static file server
```

## How the Pieces Connect

### Subservice (ttyd backend)

ArozOS scans `./subservice/*/` on startup. For each directory, it reads `moduleInfo.json` (or runs the binary with `-info`), assigns a port, and launches the process.

The `.startscript` flag tells ArozOS to run `start.sh` instead of looking for a binary named `Terminal_linux_arm64`. The script parses ArozOS's `-port :XXXX` argument and launches ttyd.

ArozOS creates a reverse proxy: any request to `/Terminal/*` is forwarded to `localhost:PORT`. This includes WebSocket connections, which ttyd needs for xterm.js.

### Module Registration

`moduleInfo.json` serves double duty:

- **`StartDir: "Terminal/"`** — determines the reverse proxy path prefix. `filepath.Dir("Terminal/")` = `"Terminal"`, so `/Terminal/*` gets proxied.
- **`LaunchFWDir: "WebTerminal/index.html"`** — what actually opens in the float window when the user clicks the app.

This separation is important: the proxy path and the user-facing URL are different things.

### WebTerminal Wrapper

`src/web/WebTerminal/index.html` is a static page served by ArozOS's normal file server. It contains:

1. A full-viewport iframe pointing to `/Terminal/` (the proxied ttyd)
2. A toolbar div with buttons, hidden by default
3. JavaScript that shows the toolbar on touch devices and injects keystrokes

The toolbar injects keys by accessing `iframe.contentWindow.term` — ttyd exposes the xterm.js Terminal instance as `window.term`. Since both the wrapper and ttyd are served through the same ArozOS origin, there are no cross-origin restrictions.

Key injection uses `term._core.coreService.triggerDataEvent(sequence, true)`, which fires xterm's `onData` event. ttyd's handler picks this up and sends it through the WebSocket to the pty.

## Gotchas and Lessons Learned

### This is a webshell

The Terminal app is, by design, a webshell — it gives authenticated users full shell access to the host through a browser. This is the intended functionality for a web desktop environment like ArozOS, but it means the security model depends entirely on ArozOS's authentication layer. If ArozOS auth is bypassed, the attacker has shell access. Keep this in mind when deploying: use HTTPS, strong credentials, and don't expose the instance to the public internet without additional access controls.

### Icon path conflicts with reverse proxy

The reverse proxy catches any request starting with `/Terminal/`. This means an icon at `Terminal/img/icon.png` would be forwarded to ttyd (which returns 404). The icon must live outside the proxy path — we use `img/subservice/terminal.png` instead.

**Rule: never put static assets under a path that matches a subservice's proxy endpoint.**

### ttyd doesn't need `-b` (base-path)

ArozOS's reverse proxy strips the path prefix before forwarding. A request to `/Terminal/foo` arrives at ttyd as `/foo`. If you set ttyd's `-b /Terminal/`, it expects the prefix and everything 404s.

**Rule: don't set `-b` when running behind ArozOS's subservice proxy.**

### Subservice name conflicts with webapp path

ArozOS's proxy path matching is a prefix check: `requestURL[1:len(endpoint)+1] == endpoint`. A webapp at `/TerminalApp/` would match `Terminal` and get proxied to ttyd. The wrapper lives at `/WebTerminal/` to avoid this.

**Rule: webapp directories must not start with the same string as a subservice proxy endpoint.**

### Orphaned ttyd processes

When ArozOS is killed with `kill -9`, the ttyd child process becomes orphaned and keeps the port bound. The next ArozOS launch fails to start ttyd because the port is in use. ArozOS then auto-restarts the subservice after 10 seconds, which may or may not succeed.

**Fix: always kill ttyd explicitly when stopping ArozOS, or use `pkill -f "ttyd.*12810"` to clean up orphans.**

### `disableReconnect` for clean shell exit

Without `-t disableReconnect=true`, ttyd respawns the shell when it exits (Ctrl-D / `exit`). The new shell starts in the subservice directory with a broken `getcwd`. With `disableReconnect`, the terminal shows a "press Enter to reconnect" message instead.

Auto-closing the ArozOS float window on shell exit would require either a custom ttyd index.html or cross-frame communication with ArozOS's window manager — tracked as a future improvement.

### Mobile sidebar overlap

On ArozOS's mobile UI, the sidebar is 30px wide but has a toggle arrow that extends 20px into the main frame area. The toolbar uses `margin-left: 20px` with `width: calc(100% - 20px)` to clear this. The offset is applied dynamically only when a `.taskBar` element is detected in the parent frame.

Using `padding-left` instead of `margin-left` creates scrollable blank space (padding is inside the scroll container). Using `margin-left` without constraining width causes overflow to the right.

### Touch detection

The toolbar uses `matchMedia("(any-pointer: coarse)")` to detect touch devices. This works reliably on phones but not in desktop browser responsive mode (which doesn't change the pointer capability). To test on desktop, override `matchMedia` in the console.

### `window.term` API

ttyd exposes `window.term` (the xterm.js Terminal instance) and `window.term.fit()` (triggers resize). Key injection path:

```
term._core.coreService.triggerDataEvent(escapeSequence, true)
  → fires xterm onData event
    → ttyd's handler encodes as "0" + data
      → sends via WebSocket to pty
```

## Key Escape Sequences Reference

| Button | Sequence | Notes |
|--------|----------|-------|
| Tab | `\x09` | |
| Ctrl-C | `\x03` | Interrupt |
| Esc | `\x1b` | |
| Arrow Up/Down/Left/Right | `\x1b[A/B/D/C` | |
| Ctrl-R | `\x12` | Reverse search |
| Ctrl-D | `\x04` | EOF / exit |
| Ctrl-Z | `\x1a` | Suspend |
| Ctrl-L | `\x0c` | Clear |
| Home / End | `\x1b[H` / `\x1b[F` | |
| PgUp / PgDn | `\x1b[5~` / `\x1b[6~` | |
| Shift-Enter | `\x1b[13;2u` | CSI u encoding, for pi |
| Detach | `\x02d` | Ctrl-B then d (tmux) |
| Scroll | `\x02[` | Ctrl-B then [ (tmux) |

## Docker

The Dockerfile includes ttyd (`apt-get install ttyd`) and copies the `subservice/` directory. The `src/web/` copy includes WebTerminal and the icon.

## Open Issues

- **Mobile line wrapping** (#2): ttyd doesn't receive correct terminal dimensions on ArozOS mobile UI, causing wrapped prompts to render incorrectly.
- **Auto-close on exit**: Float window stays open after shell exits. Would need custom ttyd frontend or ArozOS window manager integration.
- **Icon source**: `terminal.png` is from [dhanishgajjar/terminal-icons](https://github.com/dhanishgajjar/terminal-icons) (MIT License), noted in `start.sh`.
