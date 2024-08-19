{pkgs, pkgsCross}: { rev, hash }:
let src = pkgs.fetchFromGitHub {
  owner = "DragonMinded";
  repo = "libdragon";
  rev = rev;
  hash = hash;
};
# N64_INST for building the lib
build_inst = pkgs.buildEnv {
  name = "libdragon-n64-inst";
  paths = map toString [
    pkgsCross.buildPackages.binutils
    pkgsCross.buildPackages.gcc
  ];
};
lib = pkgs.stdenv.mkDerivation {
  pname = "libdragon";
  version = rev;
  src = src;
  enableParallelBuilding = true;
  preBuild = "export N64_INST=${build_inst}";
  preInstall = "export N64_INST=$out";
};
mkTool = (import ./mkLibDragonTool.nix {pkgs = pkgs; libdragon_src = src; rev = rev; });
tool_chksum64 = (mkTool "chksum64");
tool_n64tool = (mkTool "n64tool");
tool_n64sym = (mkTool "n64sym");
in
{
  lib = lib;

  tools = {
    chksum64 = tool_chksum64;
    n64tool = tool_n64tool;
    n64sym = tool_n64sym;
  };

  n64_inst = pkgs.buildEnv {
    name = "libdragon-n64-inst";
    paths = map toString [
      pkgsCross.buildPackages.binutils
      pkgsCross.buildPackages.gcc
      lib
      tool_chksum64
      tool_n64tool
      tool_n64sym
    ];
  };
}
