# VNote 4.7.0 — wrapper around the vendor's AppImage.
#
# Why not built from source: nixpkgs pins 3.20.1 (the 4.x bump, PR #541070, is
# still an unmerged draft), and a source build of 4.x compiles fine but cannot
# start. QtWebEngine aborts while constructing the first QWebEngineProfile:
#
#   ERROR extension_system_qt.cpp:81]  Failed to parse extension manifest.
#   FATAL extension_system_qt.cpp:316] Check failed: pdfManifestDict.
#     #10 vnotex::WebEngineProfileService::WebEngineProfileService()
#
# IDR_PDF_MANIFEST does not come back as parseable JSON from the resource pak,
# and QtWebEngine reads it with a hard CHECK(), so the process dies before any
# VNote code runs. This reproduces upstream (vnotex/vnote#2705: self-compiled
# 4.x on Qt 6.10/6.11, same message; maintainer closed it as environment-side)
# and is not reachable from a Nix expression — the extension init is
# unconditional (ProfileQt calls InitForRegularProfile(true) with the argument
# hardcoded), so --disable-extensions / QTWEBENGINE_CHROMIUM_FLAGS cannot skip
# it. nixpkgs' -DQT_FEATURE_webengine_sanitizer=ON (PR #546987) turns more of
# these recoverable paths fatal, but does not cause this one.
#
# The AppImage ships its own Qt/QtWebEngine/OpenSSL, so it is unaffected. This
# wraps it in an FHS env, but extraction is done by hand (not wrapType2) so the
# bundled glib can be stripped -- see the postExtract comment below.
# The bundled QtKeychain wants libsecret, which the appimageTools FHS env
# already provides.
{
  appimageTools,
  lib,
  fetchurl,
  makeDesktopItem,
  cacert,
}:

let
  pname = "vnote";
  version = "4.7.0";

  src = fetchurl {
    url = "https://github.com/vnotex/vnote/releases/download/v${version}/VNote-${version}-linux-x64.AppImage";
    hash = "sha256-a7LQo2g3Nc+x7/u6l3Ju7qvuZbclYvLIuBdjsO7VhaE=";
  };

  # appimageTools' wrapper installs only $out/bin/vnote, so without this the
  # app never shows up in launchers (fuzzel lists $XDG_DATA_DIRS/applications).
  # Fields mirror upstream's src/data/core/vnote.desktop.
  desktopItem = makeDesktopItem {
    name = "vnote";
    desktopName = "VNote";
    genericName = "Note-taking Application";
    comment = "A pleasant note-taking platform";
    exec = "vnote %F";
    icon = "vnote";
    terminal = false;
    categories = [ "Utility" ];
    mimeTypes = [ "text/markdown" ];
  };

  icon = fetchurl {
    url = "https://raw.githubusercontent.com/vnotex/vnote/v${version}/src/data/core/logo/256x256/vnote.png";
    hash = "sha256-E4wxMxS/ZT4S1Za8mNnWSBuzDObynlC+VTJSeOLtqQw=";
  };

  # wrapType2 calls appimageTools.extract internally with no hook, so the
  # extraction is done here instead. postExtract removes the AppImage's
  # bundled glib before the FHS wrapper is built; see the comment below.
  unpacked = appimageTools.extract {
    inherit pname version src;

    postExtract = ''
      # Notebook sync stores its git PAT through QtKeychain, which is linked
      # statically into the vnote binary and dlopen()s libsecret on the first
      # credential job. nixpkgs' libsecret 0.21.7 needs g_task_set_static_name
      # (glib >= 2.76), but the AppImage bundles its own older glib and AppRun
      # puts $APPDIR/usr/lib first on the loader path, so the stale glib wins:
      #
      #   libsecret-1.so: LOAD FAILED: undefined symbol: g_task_set_static_name
      #
      # That makes QtKeychain's isAvailable() false, which surfaces as a bare
      # "Unknown error" and leaves sync permanently un-enablable:
      #
      #   Warning: enableSyncForNotebook: keychain store failed: "Unknown error"
      #
      # AppImage's own excludelist warns that privately bundling glib/gobject
      # breaks libsecret, so drop the family and let the FHS env's copy -- which
      # libsecret was built against -- be found instead. Both lib locations are
      # swept: linuxdeploy writes to usr/lib, but upstream's copy step also
      # lands things in usr/local/lib.
      for lib in libglib-2.0 libgobject-2.0 libgio-2.0 libgmodule-2.0 libgthread-2.0; do
        rm -f $out/usr/lib/$lib.so.0* $out/usr/local/lib/$lib.so.0*
      done
    '';
  };
in
appimageTools.wrapAppImage {
  inherit pname version;
  src = unpacked;

  extraInstallCommands = ''
    install -Dm444 ${desktopItem}/share/applications/vnote.desktop \
      $out/share/applications/vnote.desktop
    install -Dm444 ${icon} $out/share/icons/hicolor/256x256/apps/vnote.png
  '';

  # Notebook sync (git clone) verifies TLS through the OpenSSL the AppImage
  # bundles, which upstream compiled with the default prefix (/usr/local/ssl)
  # -- a path that exists on no Nix machine. Its trust store is therefore
  # empty, and every clone dies with:
  #   libgit2 error rc=-17 klass=16: the SSL certificate is invalid
  # OpenSSL's default-verify loader reads SSL_CERT_FILE before its compiled-in
  # path, so pointing it at the NixOS bundle fixes verification. Same approach
  # as nixpkgs' anki-bin, which hits this with its bundled Qt.
  profile = ''
    export SSL_CERT_FILE="${cacert}/etc/ssl/certs/ca-bundle.crt"
  '';

  meta = {
    homepage = "https://vnotex.github.io/vnote";
    description = "Pleasant note-taking platform";
    mainProgram = "vnote";
    # Binary release, not built from the vnotex/vnote sources.
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    license = lib.licenses.lgpl3Plus;
    platforms = lib.platforms.linux;
  };
}
