{ config, pkgs, ... }:

let
  nixglOverlay = import <nixgl>;
  nixglPkgs = pkgs.extend nixglOverlay;
in
{
  home.username = "josh";
  home.homeDirectory = "/home/josh";
  home.stateVersion = "26.05";

  # Core packages for the Niri desktop environment
  home.packages = [
    nixglPkgs.auto.nixGLDefault
    pkgs.niri
    pkgs.quickshell
    pkgs.fuzzel
    pkgs.alacritty
    pkgs.xdg-desktop-portal-gtk
  ];

  # Wrapper script that ensures nixGL is in PATH before launching niri-session
  home.file.".local/bin/niri-session-hm" = {
    executable = true;
    text = ''
      #!/usr/bin/env bash
      export PATH="${config.home.profileDirectory}/bin:$PATH"
      exec nixGL niri-session
    '';
  };

  # Wayland session desktop entry for GDM
  home.file.".local/share/wayland-sessions/niri-nix.desktop".text = ''
    [Desktop Entry]
    Name=Niri (Nix)
    Comment=A scrollable-tiling Wayland compositor (via Nix + NixGL)
    Exec=/home/josh/.local/bin/niri-session-hm
    Type=Application
    DesktopNames=niri
  '';

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

  programs.home-manager.enable = true;
}
