| :exclamation:  I'm no longer using nixos so i'm archiving the project   |
|----------------------------------------------|

# Self-Updating Cursor Flake

A Nix flake that provides the Cursor code editor with automatic daily updates via GitHub Actions.

## Features

- 🚀 **Self-updating**: Automatically checks for new Cursor versions daily
- 🔧 **Manual updates**: Local script for immediate updates
- 🛡️ **Robust**: Proper error handling and fallbacks
- 📦 **AppImage-based**: Uses Cursor's official AppImage for maximum compatibility
- 🎯 **Linux x86_64**: Optimized for Linux AMD64 architecture

## Quick Start

### Method 1: Direct Installation
```bash
# Install Cursor directly
nix profile install github:your-username/cursor-nixos-flake

# Run Cursor
cursor --version
```

### Method 2: Add to Your Flake
Add to your `flake.nix` inputs:
```nix
inputs.cursor.url = "github:your-username/cursor-nixos-flake";
```

Then use in your configuration:
```nix
# For NixOS system configuration
environment.systemPackages = with pkgs; [
  cursor.packages.x86_64-linux.cursor
];

# For home-manager
home.packages = with pkgs; [
  cursor.packages.x86_64-linux.cursor
];

# For devShell
devShells.default = pkgs.mkShell {
  packages = with pkgs; [
    cursor.packages.x86_64-linux.cursor
  ];
};
```

### Method 3: Temporary Run
```bash
# Run without installing
nix run github:your-username/cursor-nixos-flake

# Build and run
nix build github:your-username/cursor-nixos-flake
./result/bin/cursor
```

## Manual Update

To manually update Cursor to the latest version:

```bash
./update-cursor.sh
```

To update to a specific version:

```bash
./update-cursor.sh 1.8.0
```

## How It Works

### Automatic Updates
The GitHub Actions workflow runs daily and:
1. Checks Cursor's API for the latest version
2. Only updates if a new version is available
3. Downloads the AppImage and calculates SHA256 hash
4. Updates `flake.nix` with new version and hash
5. Tests the build and commits changes
6. Creates a GitHub release for tracking

### Manual Updates
The `update-cursor.sh` script provides:
- Version checking and comparison
- Safe updates with backups
- Build validation
- Interactive confirmation prompts

## API Endpoints

- **AppImage Download**: `https://api2.cursor.sh/updates/download/golden/linux-x64/cursor/{version}`

## Testing

```bash
# Test the complete setup
./test-setup.sh

# Test flake syntax
nix flake check

# Test building
nix build '.#cursor' --dry-run
```

## Development

### Customization
- **Update frequency**: Modify cron schedule in `.github/workflows/update-cursor.yml`
- **API endpoints**: Update URLs in workflow and update script
- **Build options**: Modify the `buildCursor` function in `flake.nix`

## License

MIT License - see [LICENSE](LICENSE) file for details.
