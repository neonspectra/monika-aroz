# NixOS Packaging and Deployment

This document covers the Nix flake, package derivation, NixOS service module, and
deployment patterns for running Aroz on NixOS. It is written to be sufficient for
working on the packaging from cold — no prior context required.

## Architecture Decision: Native NixOS vs. Container

Aroz runs as a native NixOS service, not inside a Docker container. This is a deliberate
choice driven by the long-term direction of this fork.

The goal is a browser-based desktop environment where NixOS handles system-level concerns
(package management, service lifecycle, storage, users) and Aroz owns the interactive
desktop layer (windowing, file management UI, webapps, terminal). Containerizing Aroz
would create an isolation boundary between the desktop and the system it's meant to
manage — defeating the point. The native approach lets Aroz's subservices (like the
terminal) operate directly on the host, and lets NixOS manage the binary, assets, and
service lifecycle declaratively.

The tradeoff is that NixOS's filesystem conventions (no `/bin/bash`, read-only Nix store,
no FHS) require patching at the packaging layer. The package and module handle this
transparently.

## Flake Structure

```
flake.nix           Flake definition — package, module, overlay
flake.lock          Pinned nixpkgs (nixos-25.11)
nix/
├── package.nix     buildGoModule derivation
└── module.nix      NixOS service module (services.aroz)
```

The flake exports:

| Output | Description |
|--------|-------------|
| `packages.${system}.default` | The Aroz package (binary + assets) |
| `packages.${system}.aroz` | Same, named explicitly |
| `nixosModules.default` | NixOS service module |
| `nixosModules.aroz` | Same, named explicitly |
| `overlays.default` | Overlay that adds `pkgs.aroz` |

## Package (`nix/package.nix`)

The package uses `buildGoModule` against the `src/` directory. Key details:

- **Go module path**: `imuslab.com/arozos` (upstream's, unchanged)
- **Binary name**: `arozos` (matches upstream expectations; the Nix *package* is named `aroz`)
- **vendorHash**: Nix fetches Go dependencies independently — the upstream `vendor/`
  directory is ignored because its `modules.txt` is stale
- **Build tags**: `netgo` (pure Go networking)
- **ldflags**: `-s -w` (strip debug info)

### What the package contains

```
$out/
├── bin/arozos                    Wrapper script (sets PATH, execs binary)
└── share/aroz/
    ├── web/                      Static webapps (immutable)
    ├── system/                   Config templates, HTML templates, geoip data
    └── subservice/               Subservice definitions (Terminal/start.sh, etc.)
```

### Runtime dependencies via wrapper

The binary is wrapped with `makeWrapper` to prepend `ffmpeg` and `ttyd` to `PATH`.
ArozOS discovers these at runtime via `exec.LookPath` / `which`. Without the wrapper,
ArozOS would report ffmpeg as missing and the terminal subservice wouldn't find ttyd.

The wrapper script (`$out/bin/arozos`) sets up PATH and then `exec`s the real binary
at `$out/bin/.arozos-wrapped`.

### Updating the vendorHash

When Go dependencies change (new modules, version bumps in `go.mod`):

1. Set `vendorHash` to a dummy value: `sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=`
2. Run `nix build` — it will fail with `got: sha256-...`
3. Replace the dummy with the real hash

## NixOS Module (`nix/module.nix`)

### Quick start

Add the flake input and import the module:

```nix
# flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    aroz.url = "github:spectrasecure/aroz";
    aroz.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { nixpkgs, aroz, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        aroz.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

Then in your NixOS configuration:

```nix
# configuration.nix
{
  services.aroz = {
    enable = true;
    port = 8090;
    hostname = "My Desktop";
    openFirewall = true;
  };
}
```

### Using with an existing user

By default, the module creates a system user `aroz`. To run under an existing user:

```nix
{
  services.aroz = {
    enable = true;
    port = 8090;
    user = "myuser";
    group = "users";
    dataDir = "/persist/aroz";   # impermanence-friendly path
  };
}
```

The module only creates the user/group when they're set to the default `"aroz"`. When
overridden, you're responsible for ensuring the user exists.

### With Tailscale Serve (HTTPS)

```nix
{
  services.tailscale.enable = true;
  services.tailscale.permitCertUid = "myuser";  # allow cert provisioning

  services.aroz = {
    enable = true;
    port = 8090;
    user = "myuser";
    group = "users";
  };
}
```

Then after deployment:

```bash
sudo tailscale serve --bg http://localhost:8090
```

The service is now available at `https://<hostname>.<tailnet>.ts.net/` with automatic
TLS certificate provisioning. No Caddy, no ACME config, no cert rotation.

### With built-in TLS

```nix
{
  services.aroz = {
    enable = true;
    port = 8090;
    tls = {
      enable = true;
      port = 8443;
      certFile = "/path/to/cert.pem";
      keyFile = "/path/to/key.pem";
      disableHttp = false;  # set true for HTTPS-only
    };
  };
}
```

### Module options reference

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable the Aroz service |
| `package` | package | `pkgs.aroz` | The Aroz package to use |
| `port` | port | `8080` | HTTP listening port |
| `hostname` | string | `"Aroz"` | Display name shown in the UI |
| `dataDir` | path | `"/var/lib/aroz"` | Working directory for all mutable state |
| `user` | string | `"aroz"` | User to run the service as |
| `group` | string | `"aroz"` | Group to run the service as |
| `maxUploadSize` | int | `8192` | Maximum upload size in MB |
| `openFirewall` | bool | `false` | Open the HTTP (and TLS) port in the firewall |
| `extraFlags` | list of string | `[]` | Additional CLI flags passed to `arozos` |
| `tls.enable` | bool | `false` | Enable built-in TLS |
| `tls.port` | port | `8443` | HTTPS listening port |
| `tls.certFile` | path | — | TLS certificate path (required if tls.enable) |
| `tls.keyFile` | path | — | TLS key path (required if tls.enable) |
| `tls.disableHttp` | bool | `false` | Disable HTTP entirely (HTTPS only) |

### What the module disables by default

The module passes these flags to ArozOS, disabling sysadmin features that conflict with
or duplicate NixOS's role:

| Flag | Why disabled |
|------|-------------|
| `-allow_pkg_install=false` | NixOS manages packages declaratively |
| `-enable_hwman=false` | Hardware management belongs to NixOS |
| `-enable_pwman=false` | Power management belongs to NixOS/systemd |
| `-allow_mdns=false` | Not needed for Tailscale-based access |
| `-allow_ssdp=false` | Windows network discovery, not relevant |
| `-allow_upnp=false` | UPnP port forwarding, not relevant |
| `-disable_ip_resolver=true` | Avoids unnecessary external lookups |

To re-enable any of these, use `extraFlags`:

```nix
services.aroz.extraFlags = [ "-allow_mdns=true" "-allow_cluster=true" ];
```

See [configuration.md](configuration.md) for the full flag reference.

## Asset Management: Immutable vs. Mutable

ArozOS expects three asset directories in its working directory. They have different
mutability requirements:

### `web/` — Immutable (symlinked from Nix store)

Static webapps: HTML, JS, CSS, icons, AGI scripts. ArozOS reads but never writes to
this directory. The module symlinks it directly from the Nix store:

```
{dataDir}/web → /nix/store/{hash}-aroz-{version}/share/aroz/web
```

This symlink updates automatically on package upgrades.

### `subservice/` — Mutable copy (patched)

Subservice definitions including `start.sh` launcher scripts. Must be a mutable copy
rather than a Nix store symlink for two reasons:

1. **Shebang patching**: Scripts ship with `#!/bin/bash`, which doesn't exist on NixOS.
   The activation script patches line 1 to `#!/usr/bin/env bash` and any other
   `/bin/bash` references (e.g., the argument to `ttyd`) to the Nix store bash path.

2. **Runtime state**: ArozOS may need to write to this directory for subservice
   management.

The directory is re-copied and re-patched on package version changes.

### `system/` — Mutable copy (seeded once)

A mix of static templates and runtime state:

**Templates and static assets** (shipped with the package, never modified at runtime):
- `system/agi/error.html` — AGI error page
- `system/auth/register.html`, `regsetting.html` — registration UI
- `system/errors/*.html` — HTTP error pages
- `system/ldap/newPasswordTemplate.html` — LDAP password reset
- `system/newitem/*` — "New File" templates
- `system/reset/*.html` — password reset email templates
- `system/share/*.html` — file sharing pages and assets
- `system/www/*.html` — webroot fallback pages
- `system/geoip.json` — IP geolocation data
- `system/time/wintz.json` — Windows timezone mapping
- `system/ssdp.xml`, `ssdp_printer.xml` — SSDP descriptors
- `system/update.json` — version metadata
- `system/disk/smart/*`, `system/hardware/*` — platform-specific binaries (unused on NixOS)

**Runtime state** (created by ArozOS during operation):
- `system/ao.db` — main application database (Bolt)
- `system/auth/authlog.db` — authentication log database
- `system/bridge.json` — network bridge configuration
- `system/cron.json` — scheduled task definitions
- `system/smtp_conf.json` — SMTP settings (if configured)
- `system/logs/system/system_*.log` — system logs (monthly rotation)
- `system/logs/subservice/subserv_*.log` — subservice logs (monthly rotation)

The module seeds `system/` on first run by copying from the Nix store. On upgrades, new
files are copied without overwriting existing ones (`cp -rn`), preserving databases and
configuration that ArozOS has written. A version marker at `{dataDir}/.aroz-pkg-version`
tracks whether the seeded version matches the current package.

### Filesystem layout at runtime

After deployment, the data directory looks like:

```
{dataDir}/
├── .aroz-pkg-version          Version marker (triggers re-seed on upgrade)
├── web -> /nix/store/…        Symlink to immutable webapps
├── subservice/                Mutable copy (patched shebangs)
│   └── Terminal/
│       ├── start.sh           #!/usr/bin/env bash, ttyd path patched
│       └── moduleInfo.json
├── system/                    Mutable copy (seeded, then owned by ArozOS)
│   ├── ao.db                  Main database (created at runtime)
│   ├── auth/                  Auth DB + registration templates
│   ├── logs/                  Monthly log files
│   └── …                     Templates, config, static data
├── files/                     User file storage
│   └── users/{username}/      Per-user sandboxed directories
└── tmp/                       Temporary upload/processing storage
    ├── users/
    └── webdav/
```

## Systemd Service Details

The service unit includes several NixOS-specific configurations worth understanding:

### Process group management

```nix
KillMode = "control-group";
```

ArozOS spawns subservice child processes (notably ttyd for the terminal). Without
`control-group` kill mode, stopping the service would orphan these children, holding
ports and potentially conflicting on restart.

### System PATH

```nix
path = with pkgs; [ bash coreutils which ];
```

Systemd services on NixOS get a minimal PATH (coreutils, findutils, gnugrep, gnused,
systemd). ArozOS shells out to utilities not in this default set:
- `which` — used by `apt.PackageExists()` to detect installed tools
- `bash` — spawned by subservice scripts
- `coreutils` — `du` for disk usage calculations

Without these in the service PATH, ffmpeg detection fails (even though the wrapper puts
ffmpeg in PATH, ArozOS can't find `which` to check for it) and subservices can't launch.

### Filesystem hardening

```nix
ProtectSystem = "strict";
ReadWritePaths = [ cfg.dataDir ];
```

The service can only write to its data directory. The rest of the filesystem (including
`/nix/store`) is read-only. This is why subservice scripts must be copied out of the
store rather than symlinked — they need to be in a writable path.

### No PrivateTmp

```nix
PrivateTmp = false;
```

ArozOS manages its own temporary storage via the `-tmp` flag, creating `{dataDir}/tmp/`.
Systemd's `PrivateTmp` would create an isolated `/tmp` that ArozOS doesn't use, while
potentially interfering with its own temp management.

## Gotchas and Troubleshooting

### NixOS has no `/bin/bash`

The most pervasive issue. It manifests in two ways:

1. **Shebangs in shell scripts**: Any `#!/bin/bash` script fails with
   `No such file or directory`. The activation script patches these to
   `#!/usr/bin/env bash`.

2. **Hardcoded `/bin/bash` as a command argument**: The terminal subservice runs
   `ttyd ... /bin/bash`, which also fails with `No such file or directory` even though
   the error looks like it's about ttyd. The activation script patches these to the
   Nix store bash path.

If you add new subservices with shell scripts, they'll need the same treatment. The
activation script handles `*.sh` files in `{dataDir}/subservice/` automatically.

### vendorHash vs. vendor directory

ArozOS upstream ships a `vendor/` directory, but its `modules.txt` is often stale
relative to `go.mod`. Nix's `buildGoModule` validates vendor consistency strictly. The
fix: set a real `vendorHash` so Nix fetches dependencies itself, ignoring the shipped
vendor directory entirely. See "Updating the vendorHash" above.

### Activation script ordering

The activation script that creates symlinks and seeds directories depends on
`[ "specialfs" "users" ]`. On a completely fresh system (first boot after
`nixos-install`), the data directory might not exist yet. The script handles this
by running `mkdir -p` before attempting symlinks, rather than relying on
`systemd.tmpfiles.rules` having already executed.

### The version marker race

The activation script uses `{dataDir}/.aroz-pkg-version` to decide whether to re-copy
`subservice/` and re-seed `system/`. If you manually write this file (or if the package
version string doesn't change between builds), the script will skip the update. To force
a re-copy:

```bash
rm {dataDir}/.aroz-pkg-version
sudo nixos-rebuild switch --flake .#myhost
# or: sudo /nix/store/{current-system}/activate
```

### ffmpeg detection

ArozOS checks for ffmpeg by running `which ffmpeg` via Go's `exec.Command`. This
requires both:
- `ffmpeg` in PATH (provided by the `makeWrapper` in the package)
- `which` in PATH (provided by the service module's `path` option)

If you see `[AGI] ffmpeg not installed on host OS` in the journal, one of these is
missing.

### Subservice port allocation

ArozOS assigns subservice ports incrementally starting from 12810. The terminal gets
12810, additional subservices get 12811, 12812, etc. If orphaned subservice processes
hold these ports (e.g., after a `kill -9` of the main process without `KillMode =
"control-group"`), ArozOS will fail to start subservices on restart.

Check with: `lsof -i :12810`

The `control-group` kill mode in the service unit should prevent this, but if it happens:
```bash
sudo systemctl stop aroz
pkill -9 -f "ttyd.*12810"
sudo systemctl start aroz
```

### ArozOS user filesystem is sandboxed

ArozOS virtualizes its filesystem. The "User" folder in the UI maps to
`{dataDir}/files/users/{username}/`, not to the system root or the user's home
directory. This is by design — ArozOS is a multi-user web desktop with per-user
storage isolation.

## Building the package locally

```bash
# From the repo root:
nix build .#default

# Inspect the output:
ls result/bin/           # arozos wrapper + .arozos-wrapped
ls result/share/aroz/    # web/, system/, subservice/

# Test it runs:
result/bin/arozos -version
```

## Reference deployment

The [shadowsea](https://github.com/tymasconfederation/shadowsea) repository contains
a production deployment of this package on NixOS with EYD (erase-your-darlings)
impermanence. The relevant files:

- `flake.nix` — aroz flake input with `nixpkgs.follows`
- `nixos/stanza.nix` — host config with `services.aroz` block
- `nixos/STANZA.md` — host-specific operational notes

That deployment uses `dataDir = "/persist/aroz"` (durable across reboots on an
impermanence system), runs under an existing `monika` user, and serves over HTTPS via
Tailscale Serve.
