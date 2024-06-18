{ lib
, stdenvNoCC
}:

stdenvNoCC.mkDerivation {
  pname = "dracula";
  version = "git";
  src = ./.;
  dontBuild = true;

  passthru = {
    colors = lib.importJSON ./colors.json;
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/sway
    cp sway.cfg $out/sway/sway.cfg

    mkdir -p $out/waybar
    cp waybar.css $out/waybar/

    runHook postInstall
  '';
}
