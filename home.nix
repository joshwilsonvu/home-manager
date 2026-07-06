{ config, pkgs, ... }:

let
  nixglPkgs = import <nixgl> { pkgs = import <nixpkgs> {}; };
  # TODO: just use pkgs.noctalia-shell v5 when available
  # Fetching from GitHub directly because the release tarball is missing the nix/ directory
  noctalia-src = fetchTarball {
    url = "https://github.com/noctalia-dev/noctalia/archive/refs/tags/v5.0.0-beta1.tar.gz";
    sha256 = "sha256:194fhlxn79d8hg0qgczk51jrbnifnvhgikz6npqirzb0kfifxyz9";
  };
  noctalia = import noctalia-src {};
  username = "josh";
in
{
  targets.genericLinux.enable = true;
  nixpkgs.config.allowUnfree = true;
  home = {
    username = username;
    homeDirectory = "/home/${username}";
    stateVersion = "26.05";

    # Core packages for the Niri desktop environment
    packages = [
      nixglPkgs.auto.nixGLDefault
      # CLIs
      pkgs.git
      pkgs.btop
      pkgs.bun
      pkgs.gh
      pkgs.micro
      pkgs.fd
      pkgs.nodejs
      pkgs.pnpm
      pkgs.jq
      pkgs.kitty
      pkgs.fzf
      pkgs.ripgrep
      pkgs.nvtopPackages.amd # nvtop
      # desktop environment
      pkgs.niri
      pkgs.xdg-desktop-portal-gtk
      # desktop applications
      pkgs.opencode-desktop
      pkgs.zed-editor
      pkgs.obsidian
    ];
    shell.enableBashIntegration = true;

    # Wrapper script that ensures nixGL is in PATH before launching niri-session
    file.".local/bin/niri-session-hm" = {
      executable = true;
      text = ''
        #!/usr/bin/env bash
        export PATH="${config.home.profileDirectory}/bin:$PATH"
        exec nixGL niri-session
      '';
    };

    # Wayland session desktop entry for GDM
    file.".local/share/wayland-sessions/niri-nix.desktop".text = ''
      [Desktop Entry]
      Name=Niri (Nix)
      Comment=A scrollable-tiling Wayland compositor (via Nix + NixGL)
      Exec=/home/josh/.local/bin/niri-session-hm
      Type=Application
      DesktopNames=niri
    '';
  };

  # Minimal Niri config; defaults are used where omitted
  xdg.configFile."niri/config.kdl".source = ./niri-config.kdl;

  # Portal configuration required by Niri for screensharing, file dialogs, etc.
  xdg.configFile."xdg-desktop-portal/niri-portals.conf".source =
    "${pkgs.niri}/share/xdg-desktop-portal/niri-portals.conf";

  # Symlink Niri's systemd user units so niri-session can start them
  xdg.configFile."systemd/user/niri.service".source =
    "${pkgs.niri}/lib/systemd/user/niri.service";
  xdg.configFile."systemd/user/niri-shutdown.target".source =
    "${pkgs.niri}/lib/systemd/user/niri-shutdown.target";

  imports = [
    noctalia.homeModule
  ];

  programs = {
    noctalia = {
      enable = true;
  
      settings = {
        theme = {
          mode = "dark";
          source = "community";
          community = "Flexoki";
        };
        shell = {
          launch_apps_as_systemd_services = true;
          animation = {
            enabled = true;
            speed = 2.0;
          };
        };
      };
  
      systemd.enable = true;
    };
    # Apps
    obsidian.enable = true;
    zed-editor.enable = true;
    delta = {
    	enable = true;
    	enableGitIntegration = true;
    };
    
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Clean up nix weekly
  nix.gc = {
    automatic = true;
  };
}
