{
description = "Various Nintendo 64 Homebrew Development Tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    let
      ftd2xx-src = {
        "x86_64-linux" = {
          url = "https://ftdichip.com/wp-content/uploads/2022/07/libftd2xx-x86_64-1.4.27.tgz";
          version = "1.4.27";
          hash = "sha256-U3/J224e6hEN12YZgtxJoo3iKkUUtYjoozohEQpba0w=";
        };
        "aarch64-linux" = {
          url = "https://ftdichip.com/wp-content/uploads/2022/07/libftd2xx-arm-v8-1.4.27.tgz";
          version = "1.4.27";
          hash = "sha256-SOIC7M60y+nnf1RE74h9Zoc5OnTjPafeWmfCInxWeXA=";
        };
      };
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        pkgsCross = import nixpkgs { inherit system; crossSystem = { config = "mips64-elf"; }; };

        mkLibDragon = (import ./mkLibDragon.nix) { pkgs = pkgs; pkgsCross = pkgsCross; };

        # Default version for tools and devshell in this Flake
        libdragon = mkLibDragon {
          rev = "f3aae88520fd9427c969961b556d1bccdb5c89de";
          hash = "sha256-/yigAAPQWAZg5x7QbiHxdsd+PxuLLfD8oJFAweU0MoI=";
        };

        ftd2xx = pkgs.stdenv.mkDerivation {
          pname = "ftd2xx";
          version = ftd2xx-src.${system}.version;
          src = pkgs.fetchurl {
            url = ftd2xx-src.${system}.url;
            sha256 = ftd2xx-src.${system}.hash;
          };
          installPhase = ''
            mkdir -p $out/lib
            find
            cp build/libftd2xx.a $out/lib
          '';
        };

        unfloader-version = "v2.11";
        unfloader = pkgs.fetchFromGitHub {
          owner = "buu342";
          repo = "N64-UNFLoader";
          rev = unfloader-version;
          hash = "sha256-6PED7AAbNoQB+1zktw8mRkJgeEFsCjAaDXh71qYhduk=";
        };

        bass_v18 = pkgs.fetchFromGitHub {
          owner = "ARM9";
          repo = "bass";
          rev = "v18";
          hash = "sha256-xTKdgVcR2L+uWfj01Qhv2Ao9HDFBaAaM9yExhr6fmb4";
        };
        bass_v14 = pkgs.fetchFromGitHub {
          owner = "ARM9";
          repo = "bass";
          rev = "78e297331587eff0b2107dabe81ee036d2d01780";
          hash = "sha256-zYCj0JFEbS0MG3vJ0MgkXtZ/+4mJ14HDTs6C9jKEnJE=";
        };
      in
      {
        packages.chksum64 = libdragon.tools.chksum64;
        packages.n64tool = libdragon.tools.n64tool;
        packages.n64sym = libdragon.tools.n64sym;

        packages.bass_v14 = pkgs.stdenv.mkDerivation {
          pname = "bass";
          version = "v14";
          src = bass_v14;
          sourceRoot = "source/bass";
          installPhase = ''
            mkdir -p $out/bin
            cp ./bass $out/bin
          '';
        };

        packages.bass_v18 = pkgs.stdenv.mkDerivation {
          pname = "bass";
          version = "v18";
          src = bass_v18;
          sourceRoot = "source/bass";
          postPatch = ''
            # Fix build on OSX
            substituteInPlace GNUmakefile \
              --replace-fail 'ifneq ($(filter $(platform),linux bsd),)' "" \
              --replace-fail prefix out

            # Load architectures from the proper place
            substituteInPlace core/utility.cpp \
              --replace-fail "Path::program()" "\"$out/share/bass/\""

            # Fix build on Linux
            substituteInPlace ../nall/arithmetic.hpp \
              --replace-fail "#pragma once" "#pragma once
              #include <stdexcept>"
          '';
          preInstall = "mkdir -p $out/bin";
        };

        packages.bass = self.packages.${system}.bass_v14; # Default to v14 - both krom's and my tests require it

        packages.unfloader = pkgs.stdenv.mkDerivation {
          pname = "unfloader";
          version = unfloader-version;
          src = "${unfloader}/UNFLoader";
          buildInputs = [ pkgs.ncurses pkgs.libftdi ftd2xx ];
          installPhase = ''
            mkdir -p $out/bin
            cp UNFLoader $out/bin
            ln -s ./UNFLoader $out/bin/unfloader
          '';
        };

        packages.toolchain = pkgsCross.buildPackages.gcc;

        packages.mkLibDragon = mkLibDragon;

        apps.chksum64 = {
          type = "app";
          program = "${self.packages.${system}.chksum64}/bin/chksum64";
        };

        apps.UNFLoader = {
          type = "app";
          program = "${self.packages.${system}.unfloader}/bin/UNFLoader";
        };

        apps.bass = {
          type = "app";
          program = "${self.packages.${system}.bass}/bin/bass";
        };

        devShells.default = pkgs.mkShell
          {
            buildInputs = [
              libdragon.tools.chksum64
              libdragon.tools.n64tool
              libdragon.tools.n64sym
              self.packages.${system}.toolchain
              self.packages.${system}.bass
            ];
            N64_INST = libdragon.n64_inst;
          };
      }
    );
}
