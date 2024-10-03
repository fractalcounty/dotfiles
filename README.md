# dotfiles
[![macOS](https://img.shields.io/badge/macOS-Sequoia%2015.1-blue)](https://www.apple.com/macos/macos-sequoia-preview/) [![Shell](https://img.shields.io/badge/shell-fish-4CA4F7)](https://fishshell.com/) [![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

<p align="center">
  <img src="https://github.com/user-attachments/assets/9fad050e-56b0-4f02-b203-fdc1445d9583" alt="preview" width="700">
</p>

This repo is essentially three things:

1. A collection of .dotfiles for my macOS setup (i.e `~/.config/` files)
2. A set of YAML manifests defining static settings outside the scope of said dotfiles (i.e macOS system settings)
3. An interactive setup script that configures the system to use said dotifles and applies settings in the YAML configs

## Features

- Works on both fresh and existing installs
- Declarative yaml-based config for settings that can't be configured with dotfiles
- Applies macOS system settings declaratively from a `macos.yaml` file via [macos-defaults](https://github.com/dsully/macos-defaults)
- 100% idempotent, no need to run the setup script multiple times¹
- Non destructive²
- Modular setup via CLI tool with automatic and manual modes

¹ with exception of applying changes from `config.yaml` or `macos.yaml`

² using the power of git (user discrecion is advised)

## Configuration

Here's the default setup out of the box:

- OS: [macOS Sequoia 15.1](https://www.apple.com/macos/macos-sequoia-preview/)
- Terminal: [ghostty](https://github.com/ghostty-org/ghostty)
- Shell: [fish](https://fishshell.com/) w/ [Starship](https://starship.rs/guide/) prompt
- Package manager: [homebrew](https://brew.sh/)
- Theme: [Tokyo Night Storm](https://www.vscolors.com/themes/1cac7443-911e-48b9-8341-49f3880c288a-03f6b671)
- Editor: [neovim](https://neovim.io/) ([nvchad](https://nvchad.com/))
- IDE: [Visual Studio Code Insiders](https://code.visualstudio.com/insiders/) and sometimes [Cursor](https://cursor.sh/)
- Launcher: [Raycast](https://www.raycast.com/)
- SSH/secrets manager: [1Password](https://1password.com/)
- System settings: [macos-defaults](https://github.com/dsully/macos-defaults)

For a list of all installed and/or installed programs with descriptions of what they do, see the [Brewfile](https://github.com/fractalcounty/dotfiles/blob/main/Brewfile).

## Installation

> [!IMPORTANT]
> The shell scripts are still a work in progress.
> I wouldn't reccomend using them on your machine until I've polished it further.

1. Clone the repository:

   ```zsh
   git clone https://github.com/fractalcounty/dotfiles.git
   ```

   Anywhere works, but you should probably put it in the same place you store your git repos. I recommend `$HOME/Projects/`, as is the default the repo expects. You can change this in `config.yaml`.

2. Customize the repository (`config.yaml`, `macos.yaml`, `/src/` modules, `.gitignore`, etc).

   I reccomend opening it in your IDE and downloading the reccomended extensions for auto-completion, error checking and hover documentation for the `config.yaml` file (plus other goodies).

3. Backup everything (especially that which will be overwritten by symlinks you defined in `config.yaml`)

4. Install Homebrew:

   ```zsh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```

5. Navigate inside the cloned repo and install everything from the Brewfile:

   ```zsh
   brew bundle Brewfile
   ```

6. Make the main runner script executable:

   ```zsh
   chmod +x main.fish
   ```

Now would be the time to configure any software that requires partial configuration through the GUI only (i.e Raycast, 1Password, etc).

## Usage

### Running the setup script (`main.fish`)

[usage.webm](https://github.com/user-attachments/assets/b2f4e22c-a799-4fd6-9e55-2046883a7f8c)

```fish
./main.fish [--verbose]
```

The script will ask if you want to run all of the modules automatically or pick specific modules to run.

### Modules

Here's the gist of what some of the modules in the `/src/` directory do:

- 💻 `system.fish`: Applies the macOS system settings defined in [macos.yaml](https://github.com/fractalcounty/dotfiles/blob/main/macos.yaml) using [macos-defaults](https://github.com/dsully/macos-defaults)
- 🔗 `symlinks.fish`: Creates the symlinks defined in [config.yaml](https://github.com/fractalcounty/dotfiles/blob/main/config.yaml)
- 🍺 `brew.fish`: Configures Homebrew, installs everything in the [Brewfile](https://github.com/fractalcounty/dotfiles/blob/main/Brewfile), validates installation, etc.
- 🐟 `fish.fish`: Initializes the fish shell, checks for issues, and sets it as the default system shell
- 🔑 `op.fish`: Configures SSH, git, secrets, and various [1Password shell plugins](https://developer.1password.com/docs/cli/shell-plugins/)

Assuming all goes well, you should be able to just modify the dotfiles via the repo directly or via the default symlink at `$HOME/.config/` for any future configuration.

You shouldn't need to run the script again after the initial setup to apply new changes unless you modify any static settings in `config.yaml` or `macos.yaml` that can only be applied at runtime. However, there's no harm in doing so if you want to check for problems or just make sure everything's set up properly. After all, it's all declarative so there shouldn't be any suprises.

Aside from using git to track changes (which I heavily reccomend), there's nothing else to it.

#### Adding custom modules

You can run any custom modules you created in the `/src/` directory or modify the order they execute in by simply modifying the `setup_scripts` list in `main.fish`.

The list should be an ordered series of scripts to run with each containing the filename, an emoji icon, and the success message to display when the script is complete.

```fish
# Execution order is important, runs sequentially
set setup_scripts \
    "system.fish:💻:System settings successfully set!" \
    "custom.fish:✨:Custom module is working!"
```

### Configuring static settings (`config.yaml`)

The main configuration file is a fairly minimal YAML file that defines the behavior of the setup script and other settings that need to be applied at runtime. Here's a quick rundown of the main options:

```yaml
system:
  friendly_name: "Chip's MacBook" # i.e your device's name in the Find My app
  host_name: 'chips-macbook' # aka the hostname, localhost name and NetBIOS name
symlinks:
  '$REPO_DIR/config/': '$HOME/.config' # replaces ~/.config with the repo's config dir
  '$REPO_DIR/Brewfile': '$HOME/.Brewfile' # so you can just run `brew bundle --global` to install everything
brew:
  bundle_file: '$HOME/.Brewfile' # path to the homebrew Bundle symlink created above
  autoupdate: true # automatically update the Brewfile when new packages are found via homebrew-autoupdate
  autoupdate_interval: 43200 # interval in seconds to check for updates
  cleanup: false # whether to remove all installed packages not listed in the Brewfile, i.e a clean install
verbose: false # whether to print verbose output when running ./main.fish
```

### Configuring macOS system settings (`macos.yaml`)

The script uses the excellent [macos-defaults](https://github.com/dsully/macos-defaults) CLI tool to configure macOS system settings. Any settings applied by the script is defined in [macos.yaml](https://github.com/fractalcounty/dotfiles/blob/main/macos.yaml). Please refer to the project page for detailed information on how to configure the settings. Here's a quick rundown paraphrased from the README:

```zsh
# Dump current settings from a domain to a file:
macos-defaults dump -d com.apple.Dock dock.yaml

# Dump current settings from the NSGlobalDomain settings domain toa  file:
macos-defaults dump -g global.yaml

# Read current value of a specific setting:
defaults read com.apple.dock "tilesize"

# Reset a specific setting to the default value:
defaults delete com.apple.dock "tilesize" && killall Dock
```

Some settings will require a restart to take effect.

To explore important or commonly changed values, see [macos-defaults.com](https://macos-defaults.com/) and [mathiasbynens's .macos file](https://github.com/mathiasbynens/dotfiles/blob/main/.macos)

## FAQ

### Why not use stow/chezmoi/nix/etc?

Because I'm stupid and a basic git repository worked fine for my already minimal configuration. [nix-darwin](https://github.com/LnL7/nix-darwin) and [Home Manager](https://github.com/nix-community/home-manager) are probably the best solution for managing dotfiles, I just haven't had enough time to figure out Nix yet.

### How do I manage secrets and SSH keys?

I personally use the 1Password CLI, which already works seamlessly with this configuration (see [1Password: Secret References](https://developer.1password.com/docs/cli/secret-references)). However, it's not required, nor does anything strongly rely on it aside from `/config/ssh/config`, `/config/git/config`, and `/config/1Password/ssh/agent.toml` (which all can be safely removed)

The `.gitignore` file is already configured to ignore everything by default, so you should be good as long as you don't track anything sensitive.

## License

This project is licensed under the [MIT License](LICENSE).
