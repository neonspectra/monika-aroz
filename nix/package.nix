{ lib, buildGoModule, makeWrapper, ffmpeg, ttyd }:

buildGoModule {
  pname = "aroz";
  version = "unstable-2026-04-01";

  # The Go source lives in src/ — the module path is imuslab.com/arozos (upstream's).
  src = ../src;

  vendorHash = "sha256-/UkMBsQuHvQjXYBvGu/kb4aL3Ae7OcMD+6n1pSnR6bg=";

  # The binary name stays "arozos" to match upstream expectations.
  # Our package name is "aroz" but the executable is "arozos".

  nativeBuildInputs = [ makeWrapper ];

  ldflags = [ "-s" "-w" ];
  tags = [ "netgo" ];

  # ArozOS expects web/, system/, and subservice/ in its working directory.
  # Install them alongside the binary so the module can symlink/copy them.
  postInstall = ''
    mkdir -p $out/share/aroz
    cp -r ${../src/web} $out/share/aroz/web
    cp -r ${../src/system} $out/share/aroz/system
    cp -r ${../src/subservice} $out/share/aroz/subservice

    # Wrap the binary so ffmpeg and ttyd are in PATH.
    # Child processes (subservice launcher) inherit this environment.
    wrapProgram $out/bin/arozos \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg ttyd ]}
  '';

  meta = with lib; {
    description = "Aroz — web desktop environment (ArozOS fork)";
    homepage = "https://github.com/spectrasecure/aroz";
    license = licenses.asl20;
    platforms = platforms.linux;
    mainProgram = "arozos";
  };
}
