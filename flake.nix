{
  description = "Claude Desktop for Linux";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    
    # Claude parameters file - JSON with hash, version, and url
    # Override with: inputs.claude-desktop.inputs.claude-params.url = "file+file:///path/to/params.json";
    claude-params = {
      url = "file+file:///dev/null";
      flake = false;
    };
  };

  outputs =
    inputs:
    let
      inherit (inputs.nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      eachSystem = lib.genAttrs systems;
      pkgsFor = inputs.nixpkgs.legacyPackages;
    in
    {
      packages = eachSystem (
        system:
        let
          pkgs = pkgsFor.${system};
        in
        rec {
          patchy-cnb = pkgs.callPackage ./pkgs/patchy-cnb.nix { };
          claude-desktop = let
            paramsContent = builtins.readFile inputs.claude-params;
            params = if paramsContent == "" then {} else builtins.fromJSON paramsContent;
          in pkgs.callPackage ./pkgs/claude-desktop.nix ({
            inherit patchy-cnb;
          } // params);
          claude-desktop-with-fhs = pkgs.buildFHSEnv {
            name = "claude-desktop";
            targetPkgs =
              pkgs: with pkgs; [
                docker
                glibc
                openssl
                nodejs
                uv
              ];
            runScript = "${claude-desktop}/bin/claude-desktop";
            extraInstallCommands = ''
              # Copy desktop file from the claude-desktop package
              mkdir -p $out/share/applications
              cp ${claude-desktop}/share/applications/claude.desktop $out/share/applications/

              # Copy icons
              mkdir -p $out/share/icons
              cp -r ${claude-desktop}/share/icons/* $out/share/icons/
            '';
          };
          default = claude-desktop;
        }
      );
    };
}
