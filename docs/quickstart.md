# Quickstart

## Prerequisites

- **Go 1.22+** for building ArozOS
- **ffmpeg** (optional, for media transcoding)
- **ttyd** (optional, for the Terminal subservice: `apt install ttyd`)

## Build and Run

```bash
git clone git@github.com:neonspectra/monika-aroz.git
cd monika-aroz

# Build the binary
cd src && go build -o ../arozos && cd ..

# Create symlinks so ArozOS finds its assets
ln -sf src/web web
ln -sf src/system system
ln -sf src/subservice subservice

# Run
./arozos -port 8090
```

On first launch, visit `http://localhost:8090` and create an admin user.

## Docker

```bash
docker build -t arozos .
docker run -p 8090:8080 arozos
```

## Development Workflow

ArozOS serves static files from `web/` and launches subservices from `subservice/`. Because we use symlinks to `src/`, changes to web assets take effect on page reload — no rebuild needed.

| What changed | Action needed |
|---|---|
| `src/web/**` (HTML, JS, CSS) | Reload the page |
| `src/subservice/**/start.sh` | Restart ArozOS |
| `src/subservice/**/moduleInfo.json` | Restart ArozOS |
| `src/*.go` or `src/mod/**/*.go` | Rebuild binary, restart ArozOS |

### Stopping ArozOS

ArozOS spawns child processes for subservices. Kill both the parent and children:

```bash
pkill -f arozos; pkill -f "ttyd.*12810"
```

Orphaned subservice processes hold ports open and block restarts. Check with `lsof -i :12810` if something won't start.

## First User Setup

The first visit to a fresh ArozOS instance presents a user creation form. After creating the admin account, you'll be redirected to the login page. Credentials persist in `system/ao.db`.

## What's Next

- [Apps and Subservices](apps-and-subservices.md) — build your own ArozOS applications
- [AGI Reference](agi-reference.md) — complete server-side scripting API
- [Frontend API](frontend-api.md) — ao_module.js float window and file operations
- [Configuration](configuration.md) — startup flags, storage pools, vendor customization
- [Deployment](deployment.md) — platform-specific install guides, systemd, Docker
- [Architecture](architecture.md) — request routing, filesystem layers, internals
