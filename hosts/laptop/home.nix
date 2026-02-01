{ config, pkgs, inputs, ... }:

{
  imports = [
    # Import the nix-flatpak module
    inputs.nix-flatpak.homeManagerModules.nix-flatpak
  ];

  # User identity
  home.username = "m4rz3r0";
  home.homeDirectory = "/home/m4rz3r0";

  # ==========================================
  # User packages
  # ==========================================
  home.packages = with pkgs; [
    # System utilities
    fastfetch btop ripgrep unzip p7zip micro file-roller
    android-tools nixd any-nix-shell

    # Applications
    discord mpv onlyoffice-desktopeditors github-desktop antigravity

    # GNOME extensions
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.gsconnect
    nautilus-python

    # Fonts
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code

    # Terminal emulators
    alacritty
    grc
  ];

  # Flatpak
  services.flatpak = {
    enable = true;

    # Clean up unused Flatpaks automatically
    uninstallUnmanaged = true;

    packages = [
      "com.spotify.Client"
      "io.github.milkshiift.GoofCord"
      "de.philippun1.turtle"
    ];

    overrides = {
      "com.spotify.Client" = {
        Context = {
          # Force Wayland (if you use Wayland)
          sockets = ["wayland" "!x11" "!fallback-x11"];
          # Revoke access to home folder (improves privacy)
          filesystems = ["!home"];
        };
      };
    };
  };

  # ==========================================
  # Scripts (Hacking environments)
  # ==========================================
  home.file = {
    ".local/bin/launch-zed-rust" = { executable = true; text = ''#!/usr/bin/env bash
      nix develop ${config.home.homeDirectory}/.config/nix-envs/dev#rust --command zeditor''; };
    ".local/bin/launch-zed-python" = { executable = true; text = ''#!/usr/bin/env bash
      nix develop ${config.home.homeDirectory}/.config/nix-envs/dev#python --command zeditor''; };
    ".local/bin/launch-web-terminal" = { executable = true; text = ''#!/usr/bin/env bash
      NIXPKGS_ALLOW_UNFREE=1 nix develop ${config.home.homeDirectory}/.config/nix-envs/security/web --impure --command fish''; };
    ".local/bin/launch-reversing-terminal" = { executable = true; text = ''#!/usr/bin/env bash
      nix develop ${config.home.homeDirectory}/.config/nix-envs/security/reversing --command fish''; };
    ".local/bin/launch-forensics-terminal" = { executable = true; text = ''#!/usr/bin/env bash
      NIXPKGS_ALLOW_UNFREE=1 nix develop ${config.home.homeDirectory}/.config/nix-envs/security/forensics --impure --command fish''; };
  };

  # ==========================================
  # Application configuration
  # ==========================================

  # Git configuration
  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user = {
        name = "m4rz3r0";
        email = "30533649+m4rz3r0@users.noreply.github.com";
      };
      init = {
        defaultBranch = "main";
      };
    };
  };

  # Alacritty configuration
  programs.alacritty = {
    enable = true;
    settings = {
      window.opacity = 0.95;
      font.normal.family = "JetBrainsMono Nerd Font";
      font.size = 11;
    };
  };

  # Fish shell configuration
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting
      any-nix-shell fish --info-right | source
    '';
    plugins = [ { name = "grc"; src = pkgs.fishPlugins.grc.src; } ];
    shellAliases = {
      update   = "sudo nixos-rebuild switch --flake ~/nix-dotfiles/#z3r0net";
      sec-web  = "NIXPKGS_ALLOW_UNFREE=1 nix develop ~/.config/nix-envs/security/web --impure --command fish";
      sec-rev  = "nix develop ~/.config/nix-envs/security/reversing --command fish";
      sec-for  = "NIXPKGS_ALLOW_UNFREE=1 nix develop ~/.config/nix-envs/security/forensics --impure --command fish";
    };
  };

  # Direnv integration
  programs.direnv = { enable = true; nix-direnv.enable = true; };

  # Zed editor configuration
  programs.zed-editor = {
    enable = true;
    extensions = [ "nix" "toml" ];
    userSettings = {
      assistant.enabled = true;
      hour_format = "hour24";
      auto_update = false;
      telemetry.metrics = false;
      vim_mode = false;
      load_direnv = "shell_hook";
      base_keymap = "VSCode";
      theme = { mode = "system"; light = "One Light"; dark = "One Dark"; };
      ui_font_size = 16;
      buffer_font_size = 16;
      terminal = { dock = "bottom"; env = { TERM = "alacritty"; }; };
    };
  };

  # Firefox hardened (Arkenfox)
  programs.firefox = {
    enable = true;
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisablePocket = true;
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi"; installation_mode = "force_installed"; };
        "{446900e4-71c2-419f-a6a7-df9c091e268b}" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi"; installation_mode = "force_installed"; };
        "jid1-MnnxcxisBPnSXQ@jetpack" = { install_url = "https://addons.mozilla.org/firefox/downloads/latest/privacy-badger17/latest.xpi"; installation_mode = "force_installed"; };
      };
    };
    profiles.default = {
      isDefault = true;
      # Load Arkenfox user.js from input
      extraConfig = pkgs.lib.readFile "${pkgs.arkenfox-userjs}/user.js";
      settings = {
        # Disable container tabs (Contextual Identities)
        "privacy.userContext.enabled" = false;
        "privacy.userContext.ui.enabled" = false;
        "privacy.userContext.newTabContainerOnLeftClick.enabled" = false;

        # Other settings
        "signon.rememberSignons" = false;
        "widget.use-xdg-desktop-portal.file-picker" = 1;
        "browser.aboutConfig.showWarning" = false;
        "browser.compactmode.show" = true;
        "browser.cache.disk.enable" = false;
        "widget.disable-workspace-management" = true;
      };
      search = { force = true; default = "ddg"; order = [ "ddg" "google" ]; };
    };
  };

  # GNOME settings (dconf)
  dconf = {
    enable = true;
    settings = {
      "org/gnome/desktop/interface".color-scheme = "prefer-dark";
      "org/gnome/desktop/wm/preferences".button-layout = ":minimize,maximize,close";
      "org/gnome/shell" = {
        disable-user-extensions = false;
        enabled-extensions = with pkgs.gnomeExtensions; [
          blur-my-shell.extensionUuid
          gsconnect.extensionUuid
          appindicator.extensionUuid
        ];
      };
    };
  };

  # Enable Home Manager
  programs.home-manager.enable = true;
  home.stateVersion = "25.11";
}
