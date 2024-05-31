{ stdenvNoCC
}:

stdenvNoCC.mkDerivation {
  pname = "dracula";
  version = "git";
  src = ./.;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/config
    cp sway.cfg $out/config/sway.cfg

    runHook postInstall
  '';
}
