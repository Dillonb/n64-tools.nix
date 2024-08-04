{
  description = "Various Nintendo 64 Homebrew Development Tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }: flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs { inherit system; };
      libdragon = pkgs.fetchFromGitHub {
        owner = "DragonMinded";
        repo = "libdragon";
        rev = "f3aae88520fd9427c969961b556d1bccdb5c89de";
        hash = "sha256-/yigAAPQWAZg5x7QbiHxdsd+PxuLLfD8oJFAweU0MoI=";
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

      apps.chksum64 = {
        type = "app";
        program = "${self.packages.${system}.chksum64}/bin/chksum64";
      };

      devShells.default = pkgs.mkShell
        {
          buildInputs = [];
        };
    }
  );
}
