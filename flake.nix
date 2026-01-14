{
  description = "Dev env for Handin";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    systems.url = "github:nix-systems/default";
    process-compose-flake.url = "github:Platonic-Systems/process-compose-flake";
    services-flake.url = "github:juspay/services-flake";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [
        inputs.process-compose-flake.flakeModule
      ];
      perSystem =
        {
          self',
          pkgs,
          config,
          lib,
          ...
        }:
        {
          # `process-compose.foo` will add a flake package output called "foo".
          # Therefore, this will add a default package that you can build using
          # `nix build` and run using `nix run`.
          process-compose."local_db" =
            { config, ... }:
            let
              dbName = "sample";
            in
            {
              imports = [
                inputs.services-flake.processComposeModules.default
              ];

              services.postgres."pg1" = {
                enable = true;
                initialScript.before = ''
                  CREATE USER postgres WITH password 'postgres';
                  GRANT pg_read_all_data TO postgres;
                  GRANT pg_write_all_data TO postgres;
                  ALTER USER postgres CREATEDB;
                '';
                initialDatabases = [
#                  {
#                    name = "handin_dev";
#                    user = "postgres";
#                    schemas = [ ];
#                  }
                ];
              };
            };

          packages.default = self'.packages.local_db;

          devShells.default = pkgs.mkShell {
            inputsFrom = [
              # Add the packages of the enabled services in the devShell
              #
              # For example: `psql` to interact with `postgres` server or `redis-cli` with `redis-server`
              config.process-compose."local_db".services.outputs.devShell
            ];
            packages = [
              # Add the process-compose app in the devShell
              #
              # In the devShell, run `local_db` to run the app
              self'.packages.local_db
            ];
            nativeBuildInputs = with pkgs; [
              nodejs_22
              beam27Packages.erlang
              beam27Packages.elixir
              inotify-tools
            ];
          };
        };
    };
}
