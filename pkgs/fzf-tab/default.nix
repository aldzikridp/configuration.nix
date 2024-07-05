{ lib
,stdenv
,fetchFromGitHub
,runtimeShell
}:

stdenv.mkDerivation rec {
  pname = "fzf-tab-completion";
  version = "ae8462e19035af84586ac6871809e911d641a50c";

  src = fetchFromGitHub {
    owner = "lincheney";
    repo = "fzf-tab-completion";
    rev = version;
    #sha256 = lib.fakeSha256;
    sha256 = "sha256-0HAAHJqsX78QGDQ+ltUtM64RL4M1DCWzwc3kNHjoRFM=";
  };

  outputs = [ "out" ];

  phases = [ "preInstall" "installPhase" ];

  preInstall = ''
    mkdir -p $out/{bin,share}
    cp $src/bash/fzf-bash-completion.sh $out/share/fzf-bash-completion.sh
  '';

  installPhase = ''
    cat <<SCRIPT > $out/bin/fzf-tab-bash
    #!${runtimeShell}
    echo $out/share/fzf-bash-completion.sh
    SCRIPT
    chmod +x $out/bin/fzf-tab-bash
  '';
 }
