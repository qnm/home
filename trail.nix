{ pkgs, ... }:
let
  version = "0.30.5";
  trail = pkgs.buildNpmPackage {
    pname = "trail-code";
    inherit version;
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@trailhq/trail-code/-/trail-code-${version}.tgz";
      hash = "sha256-WUlNQnPFgp3T8g4L56TeQIPzGB/+8sfI2ChW/guUSEE=";
    };
    sourceRoot = "package";
    postPatch = ''
      cp ${./trail/package-lock.json} package-lock.json
      substituteInPlace dist/notes/home.js \
        --replace-fail 'return notePlaces(dir, env).some((p) => existsSync(p.dir) || (p.git && hasRepoTrail(p.checkout)));' 'return false;'
      substituteInPlace dist/notes/every-repo.js \
        --replace-fail 'export function everyRepoLearnings(env = process.env) {' 'export function everyRepoLearnings(env = process.env) { return [];'
      substituteInPlace dist/cli.js \
        --replace-fail 'await runNoteCommand(resolve(dir), opts);' 'console.error("trail note: learnings are off on this machine. Do not save one."); process.exitCode = 1; return;'
    '';
    npmDepsHash = "sha256-OXpMFL46hCWdawOvFuJYEu70s7YxpllhOpHvbHACPRs=";
    npmFlags = [ "--ignore-scripts" ];
    dontNpmBuild = true;
    nodejs = pkgs.nodejs_22;
    postInstall = ''
      chmod +x $out/lib/node_modules/@trailhq/trail-code/dist/bin/trail.js
      ln -sf ../lib/node_modules/@trailhq/trail-code/dist/bin/trail.js $out/bin/trail
    '';
    meta.mainProgram = "trail";
  };
in
{
  home.packages = [ trail ];
}
