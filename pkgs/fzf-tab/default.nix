{ lib
,stdenv
,fetchFromGitHub
,runtimeShell
}:

stdenv.mkDerivation rec {
  pname = "fzf-tab-completion";
  version = "7014e0a7cd68fe3530e2f58c45740d17e98f05b8";

  src = fetchFromGitHub {
    owner = "lincheney";
    repo = "fzf-tab-completion";
    rev = version;
    #sha256 = lib.fakeSha256;
    sha256 = "sha256-qxHvd91QOv4LATikWGaL4AqEM52volP8TCYXhpZKtsA=";
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
