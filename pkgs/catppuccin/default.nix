{ stdenvNoCC
, src
}:

stdenvNoCC.mkDerivation {
  inherit src;

  pname = "catppuccin";
  version = "git";
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/config
    cp themes/catppuccin-mocha $out/config/sway-colors.cfg
    echo "include $out/config/sway-colors.cfg" >$out/config/sway.cfg
    cat ${./sway.cfg} >>$out/config/sway.cfg

    runHook postInstall
  '';
}
