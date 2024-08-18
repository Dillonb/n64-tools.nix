{ pkgs, libdragon_src, rev }: tool:
pkgs.stdenv.mkDerivation {
  pname = "${tool}";
  version = rev;

  src = libdragon_src;

  buildPhase = ''
    $CC -o ${tool} tools/${tool}.c
    '';

  installPhase = ''
    mkdir -p $out/bin
    cp ${tool} $out/bin
    '';
}
