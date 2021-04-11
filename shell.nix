{ pkgs ? import <nixpkgs> {} }: let
  pkgs_ovl = pkgs.extend (import ./overlay.nix);
in pkgs_ovl.mkShell {
  buildInputs = [
    pkgs_ovl.esp-idf
  ];
  shellHook = pkgs_ovl.esp-idf.shellHook;
}
