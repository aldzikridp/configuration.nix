pref( 'browser.aboutConfig.showWarning', false );



////
//// Performanc tuning
////
pref( 'browser.cache.disk.enable', false );

pref( 'dom.webgpu.enabled', true );
pref( 'gfx.webrender.all', true );
pref( 'gfx.webrender.compositor', true );
pref( 'gfx.webrender.enabled', true );
pref( 'gfx.webrender.precache-shaders', true );
pref( 'gfx.webrender.svg-images', true );

pref( 'layers.acceleration.force-enabled', true );
pref( 'layers.gpu-process.enabled', true );

pref( 'media.ffvpx.enabled', false );
pref( 'media.ffmpeg.vaapi.enabled', true );
pref( 'media.hardware-video-decoding.force-enabled', true );

pref( 'network.http.max-connections', 900 );
pref( 'network.http.max-persistent-connections-per-proxy', 32 );
pref( 'network.http.max-persistent-connections-per-server', 16 );
pref( 'network.http.request.max-start-delay', 0 );


pref( 'webgl.force-enabled', true );

pref( 'browser.tabs.min_inactive_duration_before_unload', 240000 );



////
//// Low level things
////
pref( 'gfx.color_management.enablev4', true );
pref( 'gfx.color_management.native_srgb', true );
pref( 'gfx.offscreencanvas.enabled', true );



////
//// UI & UX
////
pref( 'browser.preferences.experimental', true );
pref( 'browser.protections_panel.infoMessage.seen', true );
pref( 'browser.urlbar.quicksuggest.scenario', 'history' );
pref( 'browser.urlbar.trimURLs', false );
pref( 'browser.discovery.enabled', false );
pref( 'browser.urlbar.keepPanelOpenDuringImeComposition', true );
pref( 'browser.toolbars.bookmarks.visibility', 'never');

pref( 'browser.urlbar.shortcuts.bookmarks', false ); // Annoying!
pref( 'browser.urlbar.shortcuts.history', false );
pref( 'browser.urlbar.shortcuts.tabs', false );
pref( 'browser.urlbar.suggest.engines', false );
pref( 'browser.urlbar.suggest.openpage', false );
pref( 'browser.urlbar.suggest.topsites', false );
pref( 'browser.urlbar.suggest.calculator', true );   // But calculator is fun.

pref( 'browser.tabs.insertAfterCurrent', true );
pref( 'findbar.highlightAll', true );

pref( 'general.autoScroll', true );
pref( 'general.smoothScroll.msdPhysics.enabled', true );

pref( 'media.videocontrols.picture-in-picture.audio-toggle.enabled', true );
pref( 'media.videocontrols.picture-in-picture.video-toggle.always-show', true );
pref( 'media.videocontrols.picture-in-picture.video-toggle.has-used', true );

pref( 'pref.general.disable_button.default_browser', true );

pref( 'widget.non-native-theme.gtk.scrollbar.allow-buttons', true );

pref( 'toolkit.tabbox.switchByScrolling', true );

pref( 'security.insecure_password.ui.enabled', true );
pref( 'security.insecure_field_warning.contextual.enabled', true );



////
//// Extra features
////
pref( 'dom.webshare.enabled', true );

pref( 'layout.animation.prerender.partial', true );
pref( 'layout.css.cascade-layers.enabled', true );
pref( 'layout.css.color-mix.enabled', true );
pref( 'layout.css.cross-fade.enabled', true );
pref( 'layout.css.math-depth.enabled', true );
pref( 'layout.css.motion-path-ray.enabled', true );



////
//// Security & Privacy?
////
pref( 'browser.safebrowsing.downloads.enabled', false );
pref( 'browser.safebrowsing.malware.enabled', false );
pref( 'browser.safebrowsing.downloads.remote.block_potentially_unwanted', false );

pref( 'dom.event.clipboardevents.enabled', false );
pref( 'dom.security.featurePolicy.experimental.enabled', true );

pref( 'geo.enabled', false );
pref( 'beacon.enabled', false );
pref( 'device.sensors.enabled', false );
pref( 'browser.send_pings', false );
pref( 'browser.send_pings.require_same_host', true );

pref( 'dom.battery.enabled', false );
pref( 'dom.enable_performance', false );
pref( 'dom.webnotifications.enabled', false );
pref( 'dom.enable_user_timing', false );
pref( 'dom.netinfo.enabled', false );
pref( 'dom.network.enabled', false );
pref( 'dom.telephony.enabled', false );
pref( 'dom.gamepad.enabled', false );
pref( 'dom.vr.enabled', false );

pref( 'dom.security.https_only_mode', true );
pref( 'dom.security.https_only_mode_ever_enabled', true );
pref( 'dom.security.https_only_mode_ever_enabled_pbm', true );

pref( 'media.webspeech.recognition.enable', false );
pref( 'media.webspeech.synth.enabled', false );

pref( 'fission.autostart', true );

pref( 'intl.accept_languages', 'en-US, en' );
pref( 'intl.locale.requested', 'en-US' );

pref( 'media.autoplay.default', 0 );
pref( 'media.navigator.enabled', false );
pref( 'media.navigator.video.enabled', false );
pref( 'media.peerconnection.enabled', false );
pref( 'media.navigator.mediadatadecoder_vpx_enabled', false );
pref( 'media.getusermedia.screensharing.enabled', false );
pref( 'media.getusermedia.audiocapture.enabled', false );

pref( 'network.dns.disablePrefetch', true );
pref( 'network.dns.disablePrefetchFromHTTPS', true );
pref( 'network.dns.blockDotOnion', true );

pref( 'network.predictor.enabled', false );
pref( 'network.prefetch-next', false );
pref( 'network.proxy.socks_remote_dns', true );

pref( 'pdfjs.enableScripting', false );

pref( 'privacy.resistFingerprinting', false );
pref( 'privacy.spoof_english', 1 );
pref( 'privacy.trackingprotection.socialtracking.enabled', true );

pref( 'network.manage-offline-status', false );
pref( 'network.allow-experiments', false );

pref( 'security.mixed_content.block_active_content', true );
pref( 'security.mixed_content.block_display_content', true );

pref( 'app.normandy.enabled', false );
pref( 'app.normandy.api_url', '' );
pref( 'app.shield.optoutstudies.enabled', false );

pref( 'network.cookie.thirdparty.sessionOnly', true );

pref( 'network.IDN_show_punycode', true );

pref( 'security.OCSP.enabled', 1 );
pref( 'security.OCSP.require', true );
pref( 'security.ssl.enable_ocsp_stapling', true );
pref( 'security.ssl.treat_unsafe_negotiation_as_broken', true );

pref("privacy.clearOnShutdown.cookies", false);
pref("privacy.clearOnShutdown.cache", true);
pref("privacy.clearOnShutdown.downloads", false);
pref("privacy.clearOnShutdown.history", false);
pref("privacy.clearOnShutdown.formData", false);
pref("privacy.clearOnShutdown.offlineApps", false);
pref("privacy.clearOnShutdown.sessions", false);
pref("privacy.clearOnShutdown.siteSettings", false);




////
//// Telemetry
////
pref( 'toolkit.telemetry.enabled', false );
pref( 'browser.ping-centre.telemetry', false );

pref( 'toolkit.telemetry.bhrPing.enabled', false );
pref( 'toolkit.telemetry.newProfilePing.enabled', false );
pref( 'toolkit.telemetry.firstShutdownPing.enabled', false );
pref( 'toolkit.telemetry.shutdownPingSender.enabled', false );
pref( 'toolkit.telemetry.pioneer-new-studies-available', false );
pref( 'toolkit.telemetry.reportingpolicy.firstRun', false );
pref( 'toolkit.telemetry.updatePing.enabled', false );
pref( 'toolkit.telemetry.archive.enabled', false );



////
//// Devtools
////
pref( 'devtools.everOpened', true );
pref( 'devtools.toolbox.host', 'bottom' );
pref( 'devtools.theme', 'dark' );   // Dark theme!
pref( 'devtools.chrome.enabled', true );
pref( 'devtools.webconsole.filter.css', true );


////
//// Whatever
////
pref( 'media.rdd-vpx.enabled', false );

pref( 'browser.fixup.alternate.enabled', false );
pref( 'browser.fixup.hide_user_pass', false );

pref( 'browser.uitour.enabled', false );


////
//// ipv6
////
pref( 'network.dns.disableIPv6', false );
