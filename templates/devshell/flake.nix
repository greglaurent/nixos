{
  description = "Project dev shell";

  # Pin your stack here. Commit flake.lock so the whole team + CI get identical
  # versions. Swap `nixos-unstable` for a release (e.g. nixos-26.05) if you want
  # slower-moving, more stable packages for this project.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        # ── the toolchain for THIS project (isolated from your system) ──
        packages = with pkgs; [
          git
          # nodejs_20
          # pnpm
          # python312
          # postgresql_16
          # terraform
          # awscli2
        ];

        # Optional: project env vars for a clean, accurate test environment.
        env = {
          # DATABASE_URL = "postgres://localhost/dev";
        };

        shellHook = ''
          echo "▶ $(basename "$PWD") dev shell — $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo no-git)"
        '';
      };
    };
}
