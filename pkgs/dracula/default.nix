{ stdenvNoCC
}:

stdenvNoCC.mkDerivation {
  pname = "dracula";
  version = "git";
  src = ./.;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/sway
    cp sway.cfg $out/sway/sway.cfg

    mkdir -p $out/waybar
    cp waybar.css $out/waybar/

    runHook postInstall
  '';
}
