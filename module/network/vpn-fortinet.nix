{ config, lib, pkgs, ... }:

# IPsec remote-access VPN that used to connect to fortinet vpn that uses otp:
# IKEv1 aggressive mode, XAUTH and a pre-shared group secret.  That is the same
# thing NetworkManager's libreswan plugin speaks -- it synthesises aggrmode,
# leftxauthclient, rightxauthserver, modecfgpull and the Cisco peer type on its
# own -- so FortiClient (which nixpkgs does not package) is not needed.
#
# Nothing identifying the VPN is committed here.  The gateway addresses, local
# IDs, XAUTH name, group secret and password all live in an environment file
# outside this repository and are substituted at activation time by
# NetworkManager-ensure-profiles (see the environmentFile option).  The values in
# the store are the literal "$VPN_FORTINET_..." placeholders.
#
# The FortiToken code is appended to the password with no separator, and being a
# rolling code it cannot be stored: without a passwordFile the plugin prompts for
# it on every connection attempt.
let
  cfg = config.services.vpn-fortinet;

  primary = "VPN FORTINET";
  backup = "VPN FORTINET (Backup)";

  profile = { id, gateway, localId, autoconnect }: {
    connection = {
      inherit id;
      type = "vpn";
      inherit autoconnect;
      permissions = ""; # any user may bring the connection up
    };

    vpn = {
      service-type = "org.freedesktop.NetworkManager.libreswan";
      # the plugin's key names for gateway and local ID ("gateway" is not one,
      # and unsupported keys are rejected)
      right = gateway;
      leftid = localId;
      # libreswan >= 4 dropped "leftxauthusername", the key the plugin used to
      # take here, and rejects unsupported keys outright
      leftusername = cfg.username;
      # "ike"/"esp" are left unset so that the plugin fills in its IKEv1
      # aggressive-mode defaults (aes256-sha1;modp1536 / aes256-sha1), and
      # "vendor" is left unset: the plugin already emits remote-peer-type=cisco
      # for this connection type, and libreswan advises against cisco-unity
      # unless the peer insists on it.
    } // lib.optionalAttrs (cfg.passwordFile == null) {
      xauthpasswordinputmodes = "ask";
    };

    vpn-secrets = {
      pskvalue = cfg.psk;
    } // lib.optionalAttrs (cfg.passwordFile != null) {
      xauthpassword = "$VPN_FORTINET_PASSWORD";
    };

    ipv4.method = "auto"; # addressing is handed out by the gateway
    ipv6.method = "ignore";
  };

  # The values that must never be committed.  Listed physically rather than
  # derived, since the connection profiles reference them by name.
  requiredVars = [
    "VPN_FORTINET_USERNAME"
    "VPN_FORTINET_PSK"
    "VPN_FORTINET_GATEWAY_PRIMARY"
    "VPN_FORTINET_LOCALID_PRIMARY"
    "VPN_FORTINET_GATEWAY_BACKUP"
    "VPN_FORTINET_LOCALID_BACKUP"
  ] ++ lib.optional (cfg.passwordFile != null) "VPN_FORTINET_PASSWORD";
in
{
  options.services.vpn-fortinet = {
    enable = lib.mkEnableOption "the FORTINET admin VPN (NetworkManager libreswan backend)";

    environmentFile = lib.mkOption {
      type = lib.types.str;
      default = "/etc/nixos/vpn-fortinet.env";
      example = "/etc/nixos/vpn-fortinet.env";
      description = ''
        Environment file, read by NetworkManager at activation time, holding
        every value specific to this VPN.  It must define:

        ```
        VPN_FORTINET_GATEWAY_PRIMARY=<gateway ip>
        VPN_FORTINET_LOCALID_PRIMARY=<local id>
        VPN_FORTINET_GATEWAY_BACKUP=<backup gateway ip>
        VPN_FORTINET_LOCALID_BACKUP=<backup local id>
        VPN_FORTINET_USERNAME=<xauth name>
        VPN_FORTINET_PSK=<group secret>
        ```

        optional, to let the connection come up unattended,

        ```
        VPN_FORTINET_PASSWORD=<password>
        ```

        Deliberately a *string* and not a path: a path value is copied into the
        nix store, which is world-readable.  Flake evaluation only sees
        git-tracked files, so a file inside this repository could not be used
        even if it were gitignored -- it has to live outside the repository.
        `/etc/nixos/vpn-fortinet.env` is the default; create it by hand, e.g.

        ```
        sudo install -m600 /dev/null /etc/nixos/vpn-fortinet.env
        sudoedit /etc/nixos/vpn-fortinet.env
        ```

        Only the substitution unit reads it (as root), so 0600 is enough; the
        rendered profile in /run/NetworkManager is likewise root-only.
      '';
    };

    username = lib.mkOption {
      type = lib.types.str;
      default = "$VPN_FORTINET_USERNAME";
      description = ''
        Name used for XAUTH authentication.  Defaults to a runtime environment
        variable reference; set a literal here only if you accept it being
        stored in plain text.
      '';
    };

    psk = lib.mkOption {
      type = lib.types.str;
      default = "$VPN_FORTINET_PSK";
      description = ''
        Pre-shared group secret, handed out with the SOP.  Like `username`, this
        defaults to a runtime environment variable reference.
      '';
    };

    gatewayPrimary = lib.mkOption {
      type = lib.types.str;
      default = "$VPN_FORTINET_GATEWAY_PRIMARY";
      description = "Primary gateway address, substituted at activation time.";
    };

    localIdPrimary = lib.mkOption {
      type = lib.types.str;
      default = "$VPN_FORTINET_LOCALID_PRIMARY";
      description = "Primary local ID (the group name), substituted at activation time.";
    };

    gatewayBackup = lib.mkOption {
      type = lib.types.str;
      default = "$VPN_FORTINET_GATEWAY_BACKUP";
      description = "Backup gateway address, substituted at activation time.";
    };

    localIdBackup = lib.mkOption {
      type = lib.types.str;
      default = "$VPN_FORTINET_LOCALID_BACKUP";
      description = "Backup local ID, substituted at activation time.";
    };

    passwordFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "/etc/nixos/vpn-fortinet-password.env";
      description = ''
        Environment file holding the XAUTH password in the line
        `VPN_FORTINET_PASSWORD=<password>`, which lets the connection come up
        unattended.  This only works if the account is not required to append a
        FortiToken code, i.e. if the plain password is accepted.

        When null (the default), NetworkManager asks for the password on every
        attempt -- `nmcli connection up "${primary}"` prompts on the terminal --
        and that is where the code gets appended: password and the six digits,
        no separator (`password123`, not `password 123`).  The prompt is also
        what makes the backup gateway usable.

        A string rather than a path, for the same reason as `environmentFile`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = config.networking.networkmanager.enable;
        message = "services.vpn-fortinet needs networking.networkmanager.enable.";
      }
    ];

    # The plugin shells out to the libreswan binaries and expects to find
    # /etc/ipsec.conf (pluto is started with `--config /etc/ipsec.conf`) and an
    # /etc/ipsec.secrets that includes /etc/ipsec.d/*.secrets, which is where it
    # writes the pre-shared key.  Only this module provides both; with
    # NetworkManager alone, /etc/ipsec.secrets includes just the l2tp plugin's
    # secrets file and connecting fails.
    services.libreswan.enable = true;

    # Libreswan 5 defaults to `ikev1-policy=drop`, which does not merely refuse
    # IKEv1 packets but makes loading an IKEv1 connection fail outright ("failed
    # to add connection: global ikev1-policy=drop does not allow IKEv1
    # connections").  The plugin always negotiates IKEv1 (it emits ikev2=never),
    # so without this the profile is rejected before anything is sent.  "accept"
    # is required: even "reject" blocks the connection from loading.
    #
    # This goes in its own file rather than through services.libreswan.configSetup,
    # which would replace nixpkgs' default (option defaults only apply when there
    # are no definitions) and drop virtual_private=, which pluto really does use
    # to recognise NAT'ed subnets (/etc/ipsec.conf includes /etc/ipsec.d/*.conf).
    environment.etc."ipsec.d/02-vpn-fortinet.conf".text = ''
      config setup
        ikev1-policy=accept
    '';

    # pluto only reads `config setup` at startup, and the file above is not part
    # of the libreswan module's restartTriggers, so without this a rebuild would
    # leave a running pluto on the old policy.
    systemd.services.ipsec.restartTriggers = [
      config.environment.etc."ipsec.d/02-vpn-fortinet.conf".source
    ];

    # envsubst is invoked by the nixpkgs module with fixed arguments and happily
    # substitutes an *empty* string for an unset variable, which would silently
    # produce a profile with no gateway, username or group secret.  The values
    # are already in this unit's environment via EnvironmentFile, so fail up
    # front instead.
    systemd.services.NetworkManager-ensure-profiles.serviceConfig.ExecStartPre =
      let
        checks = lib.concatMapStringsSep "\n" (v: ''
          if [ -z "''$${v}" ]; then
            echo "services.vpn-fortinet: ${v} is unset or empty in ${cfg.environmentFile}" >&2
            exit 1
          fi
        '') requiredVars;
      in
      [
        "+${pkgs.writeShellScript "vpn-fortinet-env-check" checks}"
      ];

    networking.networkmanager.plugins = [ pkgs.networkmanager-libreswan ];

    networking.networkmanager.ensureProfiles = {
      # cfg.environmentFile supplies everything above; the optional second file
      # supplies VPN_FORTINET_PASSWORD.
      environmentFiles = [ cfg.environmentFile ]
        ++ lib.optional (cfg.passwordFile != null) cfg.passwordFile;
      profiles = {
        ${primary} = profile {
          id = primary;
          gateway = cfg.gatewayPrimary;
          localId = cfg.localIdPrimary;
          autoconnect = cfg.passwordFile != null;
        };
        ${backup} = profile {
          id = backup;
          gateway = cfg.gatewayBackup;
          localId = cfg.localIdBackup;
          autoconnect = false;
        };
      };
    };
  };
}
