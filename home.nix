{ config, pkgs, lib, ... }:

let
  # make symlinks to dotfiles from version-controlled dir
  # see https://blog.daniel-beskin.com/2025-10-18-symlinking-home-manager
  inherit (config.lib.file) mkOutOfStoreSymlink;
  inherit (lib) flatten flip mergeAttrsList;

  pipe = flip lib.pipe;
  flatMerge = pipe [flatten mergeAttrsList];
  toSrcFile = name: "${homeDirectory}/.config/home-manager/${name}";
  link = pipe [toSrcFile mkOutOfStoreSymlink];
  linkFile = name: {${name}.source = link name;};
  linkDir = name: {
    ${name} = {
      source = link name;
      recursive = true;
    };
  };
  linkConfFiles = map linkFile;
  linkConfDirs = map linkDir;

  # shorthand for linking files and dirs from this directory to .config
  confFiles = linkConfFiles [];
  confDirs = linkConfDirs [
    "fontconfig"
    "spicetify"
    "niri"
    "noctalia"
    "neowall"
    "zed"
    "ghostty"
  ];
  confLinks = flatMerge [confFiles confDirs];

  username = "josh";
  homeDirectory = "/home/${username}";
in
{
  targets.genericLinux.enable = true;

  home = {
  	inherit username homeDirectory;
    stateVersion = "26.05";

    # Core packages for the Niri desktop environment
    packages = [
      pkgs.nixgl.auto.nixGLDefault
      # language support
      pkgs.python313
      pkgs.python313Packages.uv
      pkgs.libglvnd
      pkgs.mesa
      # CLIs
      pkgs.git
      pkgs.bat
      pkgs.btop
      pkgs.bun
      pkgs.gh
      pkgs.micro
      pkgs.fd
      pkgs.nodejs
      pkgs.pnpm
      pkgs.jq
      pkgs.ghostty
      pkgs.kitty
      pkgs.fzf
      pkgs.ripgrep
      pkgs.nvtopPackages.amd # nvtop
      pkgs.nixd # Nix lsp
      pkgs.fastfetch
      pkgs.spicetify-cli
      pkgs.tealdeer
      pkgs.librepods # airpods
      pkgs.pavucontrol
      # desktop environment
      pkgs.niri
      pkgs.xdg-desktop-portal-gtk
      pkgs.neowall
      # desktop applications
      pkgs.opencode-desktop
      pkgs.zed-editor
      pkgs.nwg-displays
      pkgs.qpwgraph # pipewire routing
      pkgs.jamesdsp # pipewire effects
      pkgs.lmstudio
      pkgs.vicinae
      # fonts
      pkgs.ibm-plex
      # theming
      pkgs.nwg-look
      pkgs.adw-gtk3
      pkgs.qt6Packages.qt6ct
      pkgs.pywalfox-native
    ];
    shell.enableBashIntegration = true;

    # Create desktop entry so session manager can start Niri
    file.".local/share/wayland-sessions/niri.desktop".source = ./niri.desktop;
  };

  home.file = {
  	# Symlink Niri's systemd user units into ~/.local/share/systemd/user/ so
  	# systemd can find them, but sd-switch won't restart niri mid-session.
    ".local/share/systemd/user/niri.service".source =
      "${pkgs.niri}/lib/systemd/user/niri.service";
    ".local/share/systemd/user/niri-shutdown.target".source =
      "${pkgs.niri}/lib/systemd/user/niri-shutdown.target";
    # Symlink this home-manager config dir to ~/dev/dotfiles
    "${homeDirectory}/dev/dotfiles".source = mkOutOfStoreSymlink "${homeDirectory}/.config/home-manager";
  };

  # Apply shorthand config files/dirs
  xdg.configFile = confLinks // {
    # Portal configuration required by Niri for screensharing, file dialogs, etc.
    "xdg-desktop-portal/niri-portals.conf".source =
    "${pkgs.niri}/share/xdg-desktop-portal/niri-portals.conf";
  };

  programs = {
    direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
    noctalia.enable = true;
    # Apps
    zed-editor.enable = true;
    delta = {
    	enable = true;
    	enableGitIntegration = true;
    };
    firefox.enable = true;
  };

  # Let Home Manager install and manage itself
  programs.home-manager.enable = true;

  # Clean up nix weekly
  nix.gc = {
    automatic = true;
  };
}
