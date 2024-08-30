# n64-tools.nix

Nix Flake with useful N64 homebrew development tools

## Cache

There is a cache on cachix that is built automatically on CI. To use it:

```
nix-shell -p cachix
cachix use n64-tools
```

Now you won't have to wait for tools (especially mips64-elf-gcc) to compile.

## Included tools

- chksum64
- n64tool
- mips64-elf-gcc and binutils
- UNFLoader
- libdragon
- bass
