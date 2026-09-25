final: prev:
let
  version = "0.0.399";
in
{
  github-copilot-cli = prev.github-copilot-cli.overrideAttrs (old: rec {
    inherit version;
    src = prev.fetchzip {
      url = "https://registry.npmjs.org/@github/copilot/-/copilot-${version}.tgz";
      hash = "sha256-oirzPxIqGN5si+mDQH3GaqK7WR4oYGb9Ad+wgMGS+Hc=";
    };
  });
}
