{
  description = "nix flake for simplexmq";

  inputs = {
    hackage = {
      url = "github:input-output-hk/hackage.nix";
      flake = false;
    };
    haskellNix = {
      url = "github:input-output-hk/haskell.nix/armv7a";
      inputs.hackage.follows = "hackage";
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, haskellNix, flake-utils, ... }:
    let
      systems = [
        "x86_64-linux"
      ]; # "x86_64-darwin" "aarch64-linux" "aarch64-darwin" ];
    in flake-utils.lib.eachSystem systems (system:
      let
        pkgs = haskellNix.legacyPackages.${system};
        drv' = pkgs.haskell-nix.project {
          compiler-nix-name = "ghc8107";
          index-state = "2022-06-20T00:00:00Z";
          # We need this, to specify we want the cabal project.
          # If the stack.yaml was dropped, this would not be necessary.
          projectFileName = "cabal.project";
          src = pkgs.haskell-nix.haskellLib.cleanGit {
            name = "simplex-chat";
            src = self;
          };
          sha256map = import ./scripts/nix/sha256map.nix;
          modules = [{
            packages.direct-sqlcipher.patches =
              [ ./scripts/nix/direct-sqlcipher-2.3.27.patch ];
          }];
        };
        # by defualt we don't need to pass extra-modules.
        inherit (drv') simplexmq;
      in { packages = simplexmq.components.exes; });
}
