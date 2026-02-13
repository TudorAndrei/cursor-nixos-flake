{
  description = "Cursor AppImage package flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" ];
      
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
      
      version = "2.4.36";
      
      sources = {
        x86_64-linux = {
          url = "https://downloads.cursor.com/production/f9919bf991f247689f9ead605b5c5a3239a2a794/linux/x64/Cursor-2.4.36-x86_64.AppImage";
          sha256 = "1x4fiblqh7gmd8alqx6j5d6h5xffdsmaws45lhwvf1m6q02xs1lc";
        };
        aarch64-linux = {
          url = "https://downloads.cursor.com/production/f9919bf991f247689f9ead605b5c5a3239a2a794/linux/arm64/Cursor-2.4.36-aarch64.AppImage";
          sha256 = "0l8xnpmdajhf4d838gbixc4am6xp7p33lq71d8c7273dg3hz19n4";
        };
      };
      
      buildCursor = { pkgs, system }: 
        let
          source = sources.${system};
          src = pkgs.fetchurl { 
            url = source.url;
            sha256 = source.sha256;
          };
          
          # Extract the AppImage to get access to the icon and desktop file
          appimageContents = pkgs.appimageTools.extract {
            inherit version src;
            pname = "cursor";
          };
          
          unwrapped = pkgs.appimageTools.wrapType2 {
            pname = "cursor";
            inherit version src;
            
            extraPkgs = p: with p; [
              glib gtk3 cairo pango atk gdk-pixbuf
              xorg.libX11 xorg.libXcomposite xorg.libXcursor
              xorg.libXext xorg.libXfixes xorg.libXi
              xorg.libXrandr xorg.libXrender xorg.libXtst
              nss nspr dbus at-spi2-atk at-spi2-core
              mesa alsa-lib fuse libxkbcommon xorg.libxkbfile
            ];
          };
        in
        pkgs.stdenv.mkDerivation {
          pname = "cursor";
          inherit version;
          
          nativeBuildInputs = [ pkgs.makeWrapper ];
          
          unpackPhase = "true";
          
          installPhase = ''
            mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/scalable/apps $out/share/icons/hicolor/256x256/apps $out/share/pixmaps
            
            # Create version-aware wrapper script
            cat > $out/bin/cursor << EOF
            #!/usr/bin/env bash
            if [[ "\$1" == "--version" || "\$1" == "-v" ]]; then
              echo "${version}"
              exit 0
            fi
            export CURSOR_DISABLE_UPDATE="1"
            export CURSOR_SKIP_UPDATE_CHECK="1"
            export XDG_CACHE_HOME="\$(mktemp -d -t cursor-xdg-cache-XXXXXX)"
            export CURSOR_CACHE_DIR="\$(mktemp -d -t cursor-cache-XXXXXX)"
            exec "${unwrapped}/bin/cursor" "\$@"
            EOF
            chmod +x $out/bin/cursor
            
            # Extract and install icon (try multiple possible locations and formats)
            if [ -f "${appimageContents}/cursor.png" ]; then
              cp "${appimageContents}/cursor.png" $out/share/pixmaps/cursor.png
              cp "${appimageContents}/cursor.png" $out/share/icons/hicolor/256x256/apps/cursor.png
            elif [ -f "${appimageContents}/Cursor.png" ]; then
              cp "${appimageContents}/Cursor.png" $out/share/pixmaps/cursor.png
              cp "${appimageContents}/Cursor.png" $out/share/icons/hicolor/256x256/apps/cursor.png
            elif [ -f "${appimageContents}/usr/share/pixmaps/cursor.png" ]; then
              cp "${appimageContents}/usr/share/pixmaps/cursor.png" $out/share/pixmaps/cursor.png
              cp "${appimageContents}/usr/share/pixmaps/cursor.png" $out/share/icons/hicolor/256x256/apps/cursor.png
            elif [ -f "${appimageContents}/usr/share/icons/hicolor/256x256/apps/cursor.png" ]; then
              cp "${appimageContents}/usr/share/icons/hicolor/256x256/apps/cursor.png" $out/share/pixmaps/cursor.png
              cp "${appimageContents}/usr/share/icons/hicolor/256x256/apps/cursor.png" $out/share/icons/hicolor/256x256/apps/cursor.png
            fi
            
            # Try SVG icon as well
            if [ -f "${appimageContents}/cursor.svg" ]; then
              cp "${appimageContents}/cursor.svg" $out/share/icons/hicolor/scalable/apps/cursor.svg
            elif [ -f "${appimageContents}/Cursor.svg" ]; then
              cp "${appimageContents}/Cursor.svg" $out/share/icons/hicolor/scalable/apps/cursor.svg
            elif [ -f "${appimageContents}/usr/share/icons/hicolor/scalable/apps/cursor.svg" ]; then
              cp "${appimageContents}/usr/share/icons/hicolor/scalable/apps/cursor.svg" $out/share/icons/hicolor/scalable/apps/cursor.svg
            fi
            
            # Create desktop entry
            cat > $out/share/applications/cursor.desktop << EOF
            [Desktop Entry]
            Name=Cursor
            Comment=AI-powered code editor
            GenericName=Text Editor
            Exec=$out/bin/cursor %F
            Icon=cursor
            Type=Application
            StartupNotify=true
            MimeType=text/plain;text/x-chdr;text/x-csrc;text/x-c++hdr;text/x-c++src;text/x-java;text/x-dsrc;text/x-pascal;text/x-perl;text/x-python;application/x-php;application/x-httpd-php3;application/x-httpd-php4;application/x-httpd-php5;application/javascript;application/json;text/x-markdown;text/x-web-markdown;text/html;text/css;text/x-sql;text/x-diff;
            Categories=Development;IDE;
            Keywords=editor;development;programming;ide;
            StartupWMClass=Cursor
            EOF
          '';
        };
    in
    {
      packages = forAllSystems (system: 
        let
          pkgs = import nixpkgs { inherit system; };
        in {
          default = self.packages.${system}.cursor;
          cursor = buildCursor { inherit pkgs system; };
        }
      );

      # Overlay for easy integration into other flakes
      overlays.default = final: prev: {
        cursor = self.packages.${prev.system}.cursor;
      };
    };
}
