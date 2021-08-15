{ pkgs, lib, ... }:

let
  default = import (pkgs.fetchFromGitHub {
     owner  = "mikesupertrampster";
     repo   = "nixos";
     rev    = "7430c9c4083c176e4205c88c00cb5fe725838d00";
     sha256 = "sha256:018drcpgp2a3h2z65l9djq4zhdyjr3gknjmmakg6h1a93px4cqm8";
  });
in
{
  nixpkgs.config = {
    allowUnfree = true;
    packageOverrides = pkgs: {
      nur = import (builtins.fetchTarball "https://github.com/nix-community/NUR/archive/master.tar.gz") {
        inherit pkgs;
      };
    };
  };

  imports = [
    ./interface/alacrity.nix
    ./interface/i3.nix
    ./interface/monitor.nix
    ./interface/polybar.nix
    ./interface/rofi.nix
  ];

  home = {
    homeDirectory   = default.user.home;
    username        = default.user.name;
    keyboard.layout = default.locale.keyboard.layout;

    packages = [
      pkgs.nodePackages.snyk
    ];

    sessionVariables = {
      GPG_TTY            = "$(tty)";
      KUBE_EDITOR        = "vi";
      SSH_AUTH_SOCK      = "$(gpgconf --list-dirs agent-ssh-socket)";
      PASSWORD_STORE_DIR = "${default.user.home}/.password-store";
      PASSWORD_STORE_KEY = default.work.alt;
      PASSWORD_STORE_GIT = default.work.passwordstore.git;
    };
  };

  programs = {
    autorandr.enable      = true;
    browserpass.enable    = true;
    feh.enable            = true;
    gpg.enable            = true;
    jq.enable             = true;
    home-manager.enable   = true;
    password-store.enable = true;

    chromium = {
      enable = true;
      extensions = [
        { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock
        { id = "hdokiejnpimakedhajhdlcegeplioahd"; } # lastpass
        { id = "naepdomgkenhinolocfifgehidddafch"; } # browserpass
        { id = "kaoholkoedbpjiangnchpfchhmageifp"; } # whatsapp
        { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # darkreader
        { id = "jpmkfafbacpgapdghgdpembnojdlgkdl"; } # aws
      ];
    };

    firefox = {
      enable = true;
      extensions = with pkgs.nur.repos.rycee.firefox-addons; [
        browserpass
        darkreader
        https-everywhere
        lastpass-password-manager
        multi-account-containers
        ublock-origin
      ];

      profiles = {
        "${default.user.name}" = {
          name = "${default.user.name}";
        };
      };
    };

    go = {
      enable = true;
      goPath = ".go";
    };

    mcfly = {
      enable = true;
      enableZshIntegration = true;
      keyScheme = "vim";
    };

    git = {
      enable                = true;
      userName              = default.work.name;
      userEmail             = default.work.email;
      signing.key           = "5DD715C45B3E5F63";
      signing.signByDefault = true;
      aliases = {
        co = "checkout";
        cl = "clone";
        r  = "reset";
      };

      ignores = ["*.swp" "*.idea" "bin"];

      extraConfig = {
        core = {
          editor = "vi";
        };

        pull = {
          rebase = true;
        };

        push = {
          default = "current";
        };

        url."git@github.com:".insteadOf = "https://github.com";
      };
    };

    ssh = {
      enable = true;
      compression = false;
      forwardAgent = true;

      matchBlocks = {
        "127.0.0.1" = {
          user = "core";
          certificateFile = [
            "~/.ssh/id_ecdsa-cert.pub"
            "~/.ssh/id_ecdsa"
          ];
          extraOptions = {
            StrictHostKeyChecking = "no";
          };
        };
      };
    };

    zsh = {
      enable = true;
      autocd = true;
      enableAutosuggestions = true;
      dotDir = ".config/zsh";
      history = {
        save = 100000000;
        size = 1000000000;
        expireDuplicatesFirst = true;
        ignoreDups = true;
        ignoreSpace = true;
        path = ".config/zsh/.zsh_history";
      };

      oh-my-zsh = {
        enable = true;
        plugins = [ "git" "sudo" "docker" "terraform" "helm" "bazel" "aws" "vault" "thefuck" ];
        theme = "kolo";
      };

      shellAliases = {
        g     = "git";
        k     = "kubectl";
        gcm   = "git checkout master";
        sound = "systemctl --user start edifier";
        t     = "/usr/local/bin/terraform";
        tg    = "terragrunt";
        ta    = "t apply";
        tfu   = "t force-unlock -force";
        ti    = "t import";
        taa   = "t apply --auto-approve";
        tp    = "t plan";
      };

      initExtra =  ''
        stty -ixon
        gpg-connect-agent /bye
      '' + builtins.readFile ./dotfiles/functions.sh;
    };
  };

  services = {
    blueman-applet.enable         = true;
    keybase.enable                = true;
    network-manager-applet.enable = true;

    screen-locker = {
      enable = true;
      lockCmd = "i3lock";
      inactiveInterval = 60;
    };

    udiskie = {
      enable = true;
    };

    password-store-sync = {
      enable = false;
      frequency = "*:0/5";
    };

    random-background = {
      enable = true;
      imageDirectory = "%h/.config/nixpkgs/backgrounds";
    };
  };

  systemd.user.services = {
    edifier = {
      Unit = {
        Description = "Automatically connect to edifier speakers";
        Requires    = "graphical-session.target bluetooth.target";
        After       = "graphical-session.target bluetooth.target";
      };
      Service = {
        Type      = "oneshot";
        ExecStart = "/run/current-system/sw/bin/bluetoothctl connect ${default.bluetooth.edifier}";
      };
      Install = {
        WantedBy = ["graphical-session.target" "bluetooth.target"];
      };
    };
  };
}
