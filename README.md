# SFTP-Nvim

A simple yet powerful Neovim plugin that allows you to save SFTP server configurations, upload files, and download files/folders from remote servers with an intuitive interface.

## Features

- 📁 **Bidirectional Transfer**: Upload files to remote server and download files/folders from remote
- ⚙️ **Project-based Configuration**: Save SFTP configuration per project directory
- 🔐 **Dual Authentication**: Support for SSH key and password authentication
- 🎯 **Smart File Selection**: Visual distinction between files (📄) and folders (📁)
- 🔍 **Telescope Integration**: Uses vim.ui.select() for better UX (works with Telescope, fzf, or fallback)
- 📦 **Recursive Downloads**: Download entire folders or individual files
- ⌨️ **Simple Commands**: Easy-to-use commands and key mappings

## Installation

### For LazyVim

Copy the `lazy.lua` file to your LazyVim plugins directory:

```bash
cp lazy.lua ~/.config/nvim/lua/plugins/sftp-nvim.lua
```

Or add the plugin configuration directly to your LazyVim setup:

```lua
return {
  "rafael/sftp-nvim",
  config = function()
    require("sftp-nvim").setup()
  end,
  cmd = {
    "SftpSetup",
    "SftpUpload", 
    "SftpConfig",
    "SftpDownload"
  },
  keys = {
    { "<leader>fs", "<cmd>SftpSetup<cr>", desc = "Setup SFTP config" },
    { "<leader>fu", "<cmd>SftpUpload<cr>", desc = "Upload current file via SFTP" },
    { "<leader>fc", "<cmd>SftpConfig<cr>", desc = "Show SFTP config" },
    { "<leader>fd", "<cmd>SftpDownload<cr>", desc = "Download file from remote via SFTP" },
  },
}
```

### Local Development

If you're developing this plugin locally, make sure to set `dev = true` in your plugin configuration and ensure the plugin path is in your runtimepath.

## Usage

### Commands

- `:SftpSetup` - Configure SFTP connection settings
- `:SftpUpload` - Upload the current file to the remote server
- `:SftpDownload` - Browse and download files/folders from remote server
- `:SftpConfig` - Show current SFTP configuration

### Key Mappings (default)

- `<leader>fs` - Setup SFTP config
- `<leader>fu` - Upload current file
- `<leader>fd` - Download files/folders from remote
- `<leader>fc` - Show SFTP config

### Configuration File

The plugin creates a `.sftp-config.json` file in your project root with the following structure:

```json
{
  "host": "your-server.com",
  "port": 22,
  "username": "your-username",
  "password": "your-password",
  "remote_path": "/var/www/html",
  "use_key": false,
  "key_path": "~/.ssh/id_rsa"
}
```

### Workflow

#### Upload Workflow
1. Open your project in Neovim
2. Run `:SftpSetup` to configure your server connection
3. Open any file you want to upload
4. Run `:SftpUpload` or press `<leader>fu` to upload the current file

#### Download Workflow
1. Ensure SFTP is configured (run `:SftpSetup` if needed)
2. Run `:SftpDownload` or press `<leader>fd`
3. Browse the remote files and folders:
   - 📁 Folders are listed first
   - 📄 Files are listed after folders
4. Select any file or folder to download to your current working directory

## User Interface

The download feature provides an enhanced user experience:

- **Telescope Integration**: If you have Telescope installed, you'll get a beautiful fuzzy-findable picker
- **fzf Support**: Works with fzf-lua for fast native selection
- **Fallback UI**: Simple vim selection menu if no picker is available
- **Visual Distinction**: Clear icons distinguish between files and folders
- **Cancelable**: Press `<Esc>` to cancel the selection

## File Structure

The plugin is organized in a modular structure:

```
lua/sftp-nvim/
├── init.lua        # Main entry point and command registration
├── config.lua      # Configuration management
├── upload.lua      # File upload functionality  
└── download.lua    # File/folder download and browsing
```

## Requirements

- Neovim with Lua support
- `scp` command available in your system
- For password authentication: `sshpass` (optional, for non-interactive password input)

## Authentication Methods

### SSH Key Authentication (Recommended)
- Set `use_key` to `true` during setup
- Specify path to your private key
- Ensure your public key is added to the remote server's `~/.ssh/authorized_keys`

### Password Authentication
- Set `use_key` to `false` during setup
- Enter your password (stored in config file - be careful with file permissions)
- Requires `sshpass` for non-interactive uploads

## Security Notes

- The configuration file contains sensitive information (passwords, paths)
- Consider adding `.sftp-config.json` to your `.gitignore`
- SSH key authentication is more secure than password authentication
- Set appropriate file permissions on the config file: `chmod 600 .sftp-config.json`

## Examples

### Setting up SSH key authentication:
1. Generate SSH key: `ssh-keygen -t rsa -b 4096`
2. Copy to server: `ssh-copy-id user@your-server.com`
3. Run `:SftpSetup` and choose "key" authentication
4. Specify key path (usually `~/.ssh/id_rsa`)

### Directory structure example:
```
your-project/
├── .sftp-config.json
├── src/
│   ├── main.js
│   └── utils.js
└── README.md
```

**Upload**: When uploading `src/main.js`, it will be uploaded to `remote_path/src/main.js` on the server.

**Download**: When downloading from remote, files and folders are downloaded to your current working directory maintaining their names.

## Recent Updates

- ✨ **Added Download Feature**: Browse and download files/folders from remote server
- 🎨 **Improved UI**: Replaced notifications with vim.ui.select() for better user experience  
- 📁 **Folder Support**: Download entire directories recursively
- 🏗️ **Modular Architecture**: Split code into focused modules for better maintainability
- 🔍 **Visual File Types**: Clear distinction between files and folders with icons

## Development

This plugin was developed with the assistance of AI agents to ensure clean code architecture and modern Neovim plugin best practices.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
