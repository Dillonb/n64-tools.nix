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
      };
    in
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

        libdragon = pkgs.fetchFromGitHub {
          owner = "DragonMinded";
          repo = "libdragon";
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
      in
      {
        packages.chksum64 = pkgs.stdenv.mkDerivation {
          pname = "chksum64";
          version = "1.2";

          src = libdragon;

          buildPhase = ''
            gcc -o chksum64 tools/chksum64.c
          '';

          installPhase = ''
            mkdir -p $out/bin
            cp chksum64 $out/bin
          '';
        };

        packages.unfloader = pkgs.stdenv.mkDerivation {
          pname = "unfloader";
          version = unfloader-version;
          src = "${unfloader}/UNFLoader";
          buildInputs = [ pkgs.ncurses pkgs.libftdi ftd2xx ];
          installPhase = ''
            mkdir -p $out/bin
            cp UNFLoader $out/bin
          '';
        };

        apps.chksum64 = {
          type = "app";
          program = "${self.packages.${system}.chksum64}/bin/chksum64";
        };

        apps.UNFLoader = {
          type = "app";
          program = "${self.packages.${system}.unfloader}/bin/UNFLoader";
        };

        devShells.default = pkgs.mkShell
          {
            buildInputs = [
              self.packages.${system}.chksum64
              # self.packages.${system}.unfloader
            ];
          };
      }
    );
}
