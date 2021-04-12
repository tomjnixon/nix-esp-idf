self: super: {
  esp-idf = super.callPackage ./pkgs/esp-idf.nix { };
  xtensa-esp-32-elf = super.callPackage ./pkgs/xtensa-esp-32-elf.nix { };
}
