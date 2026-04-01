![Image](img/banner.png?raw=true)

# monika-aroz

Fork of [ArozOS](https://github.com/tobychui/arozos) — a web-based desktop operating system written in Go. This fork adds a Terminal subservice, mobile touch toolbar, developer documentation, and Docker support.

## Quick Start

```bash
cd src && go build -o ../arozos && cd ..
ln -sf src/web web && ln -sf src/system system && ln -sf src/subservice subservice
./arozos -port 8090
```

Visit `http://localhost:8090` and create an admin user. See [docs/quickstart.md](docs/quickstart.md) for details.

## Repository Map

```
README.md                       ← You are here
AGENTS.md                       Agent-specific development guide
UPSTREAM-MERGE-GUIDE.md         Structural divergences from upstream + merge strategy

docs/
├── quickstart.md               Build, run, first user, Docker
├── apps-and-subservices.md     Webapp + subservice development guide
├── agi-reference.md            Complete AGI server-side scripting API
├── frontend-api.md             ao_module.js: float windows, files, utilities
├── configuration.md            Startup flags, storage pools, vendor customization
├── deployment.md               Install guides (Linux, Windows, Docker, systemd)
└── architecture.md             Request routing, filesystem layers, AGI model, internals

src/
├── web/                        Static webapps (HTML/JS/CSS + init.agi)
│   ├── WebTerminal/            Terminal wrapper app with mobile toolbar
│   │   └── DEVELOPER.md        Terminal-specific developer reference
│   ├── Music/                  Example: media player with AGI backend
│   ├── NotepadA/               Example: code editor
│   ├── SystemAO/               System UI (desktop, settings, file manager)
│   └── script/                 Shared libraries (ao_module.js, jquery)
├── subservice/                 Subservice directories (launched by ArozOS on startup)
│   └── Terminal/               ttyd subservice (web terminal backend)
├── mod/                        Go modules (subservice router, filesystems, etc.)
├── system/                     System config templates and defaults
└── *.go                        Core ArozOS source

Dockerfile                      Multi-stage Docker build
```

## Documentation

| Document | Audience | Covers |
|----------|----------|--------|
| [Quickstart](docs/quickstart.md) | Everyone | Build, run, Docker, dev workflow |
| [Apps & Subservices](docs/apps-and-subservices.md) | App developers | Building webapps, subservices, and hybrid apps |
| [AGI Reference](docs/agi-reference.md) | App developers | Server-side scripting: filelib, http, websocket, imagelib, etc. |
| [Frontend API](docs/frontend-api.md) | App developers | ao_module.js: windows, files, uploads, utilities |
| [Configuration](docs/configuration.md) | Admins/deployers | Startup flags, storage pools, vendor customization |
| [Deployment](docs/deployment.md) | Admins/deployers | Linux, Windows, Docker, systemd |
| [Architecture](docs/architecture.md) | Contributors | Request routing, filesystem layers, AGI execution model |
| [AGENTS.md](AGENTS.md) | AI agents | Testing strategies, process management, gotchas |
| [Upstream Merge Guide](UPSTREAM-MERGE-GUIDE.md) | Maintainers | Structural divergences, conflict resolution |

## What This Fork Adds

- **Terminal subservice** — web-based shell via ttyd, accessible from the ArozOS desktop
  - **Mobile touch toolbar** — Tab, Ctrl-C, Esc, arrows, tmux macros, and more for phone use
- **Docker support** — multi-stage Dockerfile with ttyd included
- **Developer documentation** — consolidated from scattered upstream sources into structured docs
- **Declarative subservices** — `src/subservice/` is tracked in git for reproducible deployments

## Screenshots

![Image](img/screenshots/1.png?raw=true)
![Image](img/screenshots/2.png?raw=true)

## License

ArozOS is licensed under **GPLv3**. See [LICENSE](LICENSE) for the full text.

Original project by [tobychui](https://github.com/tobychui). Upstream: https://github.com/tobychui/arozos
