{ lib
,stdenv
,fetchFromGitHub
,runtimeShell
}:

stdenv.mkDerivation rec {
  pname = "fzf-tab-completion";
  version = "f6f83c88eca0fc07f7820dd8bb6c7ea75ef478c5";

  src = fetchFromGitHub {
    owner = "lincheney";
    repo = "fzf-tab-completion";
    rev = version;
    #sha256 = lib.fakeSha256;
    sha256 = "sha256-AWgf8jSticYgO+qzTc/YjO1dZrh1fqSJPbgqyu/oLxE=";
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
