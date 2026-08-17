{ lib, stdenv }:
stdenv.mkDerivation {
  pname = "chksum64";
  version = "1.2";

  src = ./.;

  buildPhase = ''
    runHook preBuild
    $CC -O2 -o chksum64 chksum64.c
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 chksum64 $out/bin/chksum64
    runHook postInstall
  '';

  meta = {
    description = "Calculate the ROM checksum of Nintendo 64 ROMs";
    license = lib.licenses.gpl2Plus;
    mainProgram = "chksum64";
    platforms = lib.platforms.all;
  };
}
