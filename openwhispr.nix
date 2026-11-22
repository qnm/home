{ pkgs, lib, ... }:

let
  # macOS arm64 only: the release asset is an arm64 .dmg.
  # Keep this lazy (a plain let binding): forcing `pkgs` at module
  # top level (e.g. in a `if supported then ... else {}` guard) happens
  # during the module-system schema phase where specialArgs are absent,
  # which recurses through config._module.args and hangs evaluation.
  supported = pkgs.stdenv.hostPlatform.isDarwin && pkgs.stdenv.hostPlatform.isAarch64;

  openwhispr = pkgs.stdenv.mkDerivation rec {
    pname = "openwhispr";
    version = "1.6.10";

    src = pkgs.fetchurl {
      url = "https://github.com/OpenWhispr/openwhispr/releases/download/v${version}/OpenWhispr-${version}-arm64.dmg";
      hash = "sha256-UHz/gEpr7RNPCtHSIkGOaOPOFs2eAiYnFYQOq1OW8pc=";
    };

    nativeBuildInputs = [ pkgs.undmg ];

    sourceRoot = ".";

    installPhase = ''
      mkdir -p $out/Applications
      cp -r *.app $out/Applications/
    '';

    meta = with lib; {
      description = "Privacy-first voice-to-text dictation with AI agents";
      homepage = "https://github.com/OpenWhispr/openwhispr";
      license = licenses.mit;
      platforms = [ "aarch64-darwin" ];
    };
  };
in
{
  home.packages = lib.optional supported openwhispr;
}
