# AGENTS.md — AI Agent Development Guide

This file contains instructions specific to AI coding agents. For general development, see [docs/quickstart.md](docs/quickstart.md). For app development, see [docs/apps-and-subservices.md](docs/apps-and-subservices.md).

## Build and Test Cycle

```bash
cd src && go build -o ../arozos && cd ..
ln -sf src/web web && ln -sf src/system system && ln -sf src/subservice subservice
./arozos -port 8090
```

See [docs/quickstart.md](docs/quickstart.md) for first-run setup.

### What Needs a Restart

| Change | Action |
|--------|--------|
| `src/web/**` | Page reload |
| `src/subservice/**/start.sh` | Restart ArozOS |
| `src/subservice/**/moduleInfo.json` | Restart ArozOS |
| `src/*.go`, `src/mod/**` | Rebuild + restart |

### Process Management

ArozOS spawns child processes for subservices. Always kill both:

```bash
pkill -9 -f arozos; pkill -9 -f "ttyd.*12810"
```

Orphaned subservice processes hold ports. Check with `lsof -i :12810`. ArozOS auto-restarts crashed subservices after 10 seconds, which can create zombies if the parent was killed first.

Port 12810 is the base port for subservices. ArozOS auto-assigns incrementally from there.

## Browser Testing

ArozOS has two UIs:
- **Desktop** (`desktop.html`): float windows, standard layout
- **Mobile** (`mobile.html`): auto-redirected based on user agent matching `/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i`

Firefox responsive design mode does NOT change the user agent. To test mobile:
- Navigate directly to `http://localhost:8090/mobile.html`
- Or use a real device on the same network

To test touch-only features (e.g. terminal toolbar), inject this in the console before page load:

```javascript
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

## Key Gotchas

### Subservice proxy intercepts static files

The subservice reverse proxy check runs before static file serving. A subservice with endpoint `Terminal` intercepts all requests starting with `/Terminal/` — even if matching static files exist in `web/Terminal/`. This is why the Terminal wrapper lives at `web/WebTerminal/`.

The proxy path match is a prefix check: `requestURL[1:len(endpoint)+1] == endpoint`. A subservice at `Terminal/` also catches `/TerminalApp/`, `/TerminalFoo/`, etc.

### Symlinks are required for local dev

Without `web`, `system`, and `subservice` symlinks at the repo root pointing into `src/`, ArozOS can't find its assets.

### The Parallels shared filesystem

`/media/psf/` can cause issues with background process management and log file truncation. Prefer `nohup` or `disown` for long-running ArozOS processes. Use `> newfile.log` over truncating existing log files — truncation may not take effect immediately on the shared filesystem.

### .gitignore matters

`src/subservice/*` is un-gitignored in this fork (we ship subservices declaratively). Runtime data (`/files/`, `/tmp/`, database files) is gitignored. Always check `git status` before committing.

## Upstream Merges

See [UPSTREAM-MERGE-GUIDE.md](UPSTREAM-MERGE-GUIDE.md) for a complete list of structural divergences from upstream, conflict likelihood, and resolution strategies.

## Documentation

See the repo map and documentation index in [README.md](README.md).
