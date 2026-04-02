![Image](img/banner.png?raw=true)

# aroz

Fork of [ArozOS](https://github.com/tobychui/arozos) — a web-based desktop operating system written in Go.

## Use Case

ArozOS is distinct from most other web desktops because it is not just a PWA frontend toy that lives exclusively in the browser. While the interface itself is a clientside progressive web app, ArozOS uses the server it runs on as a filesystem and service backend. For a more complete list of features, check out the [feature listing](docs/users/features.md).

In practice, ArozOS has powerful and extensible management capabilities (akin to an overgrown home server dashboard) with direct access to backend server-side compute. This tool can touch the entire filesystem of the system that you run it on, and it has a built-in webshell straight out of the box, with all the security risks that implies.

You should understand that anyone who access your ArozOS instance effectively has local user access on your server. User discretion is advised.

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

nix/
├── package.nix                 Nix package derivation (buildGoModule + asset bundling)
└── module.nix                  NixOS service module (services.aroz)

docs/
├── quickstart.md               Build, run, first user, Docker
├── architecture.md             Request routing, filesystem layers, AGI model, internals
├── users/
│   ├── features.md             Complete feature and app inventory
│   └── storage-and-sharing.md  Storage pools, file sharing, network file servers
├── admins/
│   ├── configuration.md        Startup flags, storage pools, vendor customization
│   ├── deployment.md           Install guides (Linux, Windows, Docker, systemd)
│   └── nixos.md                Nix flake, NixOS module, packaging gotchas
└── developers/
    ├── apps-and-subservices.md  Webapp + subservice development guide
    ├── agi-reference.md        Complete AGI server-side scripting API
    └── frontend-api.md         ao_module.js: float windows, files, utilities

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
| [Features](docs/users/features.md) | Everyone | Complete feature and app inventory |
| [Storage & Sharing](docs/users/storage-and-sharing.md) | Users | Storage pools, file sharing, network file servers |
| [Apps & Subservices](docs/developers/apps-and-subservices.md) | App developers | Building webapps, subservices, and hybrid apps |
| [AGI Reference](docs/developers/agi-reference.md) | App developers | Server-side scripting: filelib, http, websocket, imagelib, etc. |
| [Frontend API](docs/developers/frontend-api.md) | App developers | ao_module.js: windows, files, uploads, utilities |
| [Configuration](docs/admins/configuration.md) | Admins/deployers | Startup flags, storage pools, vendor customization |
| [Deployment](docs/admins/deployment.md) | Admins/deployers | Linux, Windows, Docker, systemd |
| [NixOS](docs/admins/nixos.md) | Admins/deployers | Nix flake, NixOS module, packaging gotchas |
| [Architecture](docs/architecture.md) | Contributors | Request routing, filesystem layers, AGI execution model |
| [AGENTS.md](AGENTS.md) | AI agents | Testing strategies, process management, gotchas |
| [Upstream Merge Guide](UPSTREAM-MERGE-GUIDE.md) | Maintainers | Structural divergences, conflict resolution |

## What This Fork Adds

- **Terminal subservice** — web-based shell via ttyd, accessible from the ArozOS desktop
  - **Mobile touch toolbar** — Tab, Ctrl-C, Esc, arrows, tmux macros, and more for phone use
- **Docker support** — multi-stage Dockerfile with ttyd included
- **NixOS flake** — `buildGoModule` package + NixOS service module with declarative configuration
- **Developer documentation** — consolidated from scattered upstream sources into structured docs

## Screenshots

![Image](img/screenshots/1.png?raw=true)
![Image](img/screenshots/2.png?raw=true)

## License

ArozOS is licensed under **GPLv3**. See [LICENSE](LICENSE) for the full text.

Original project by [tobychui](https://github.com/tobychui). Upstream: https://github.com/tobychui/arozos
