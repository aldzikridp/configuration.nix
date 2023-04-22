{ lib
,stdenv
,fetchFromGitHub
,runtimeShell
}:

stdenv.mkDerivation rec {
  pname = "fzf-tab-completion";
  version = "f123b36c72ef3ad3e0247a0eabd59fb76872fe72";

  src = fetchFromGitHub {
    owner = "lincheney";
    repo = "fzf-tab-completion";
    rev = version;
    #sha256 = lib.fakeSha256;
    sha256 = "sha256-CCopiRRy+I/X1zWEoJIhTzGea6FOilL13z6yF8Y7MUw=";
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
