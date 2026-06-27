{ lib
,stdenv
,fetchFromGitHub
,runtimeShell
}:

stdenv.mkDerivation rec {
  pname = "fzf-tab-completion";
  version = "8ba35e65bb3792759bf17c134ce04120e5940555";

  src = fetchFromGitHub {
    owner = "lincheney";
    repo = "fzf-tab-completion";
    rev = version;
    #sha256 = lib.fakeSha256;
    sha256 = "sha256-qod3C01EK5S0Tm6rp2ia0dPVFMKRGaozpNaLQF+O9Xw=";
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
