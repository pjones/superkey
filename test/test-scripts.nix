{ stdenvNoCC
}:

stdenvNoCC.mkDerivation {
  name = "test-scripts";
  src = ./.;

  installPhase = ''
    mkdir -p "$out/bin"

    install --mode=0500 check-kill-compositor.sh "$out/bin"
    install --mode=0500 stage-for-screenshot.sh "$out/bin"
    install --mode=0500 test-lock-screen.sh "$out/bin"
  '';
}
