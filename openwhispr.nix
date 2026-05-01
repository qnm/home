{ pkgs, lib, ... }:

let
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
  home.packages = [ openwhispr ];
}
