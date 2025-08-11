# SFTP-Nvim

A simple Neovim plugin for LazyVim that allows you to save SFTP server configurations and upload files to remote servers.

## Features

- Save SFTP configuration to your project directory
- Upload current file to remote server via SFTP/SCP
- Support for SSH key and password authentication
- Simple commands and key mappings

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
    "SftpConfig"
  },
  keys = {
    { "<leader>fs", "<cmd>SftpSetup<cr>", desc = "Setup SFTP config" },
    { "<leader>fu", "<cmd>SftpUpload<cr>", desc = "Upload current file via SFTP" },
    { "<leader>fc", "<cmd>SftpConfig<cr>", desc = "Show SFTP config" },
  },
}
```

### Local Development

If you're developing this plugin locally, make sure to set `dev = true` in your plugin configuration and ensure the plugin path is in your runtimepath.

## Usage

### Commands

- `:SftpSetup` - Configure SFTP connection settings
- `:SftpUpload` - Upload the current file to the remote server
- `:SftpConfig` - Show current SFTP configuration

### Key Mappings (default)

- `<leader>fs` - Setup SFTP config
- `<leader>fu` - Upload current file
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

1. Open your project in Neovim
2. Run `:SftpSetup` to configure your server connection
3. Open any file you want to upload
4. Run `:SftpUpload` or press `<leader>fu` to upload the current file

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

When uploading `src/main.js`, it will be uploaded to `remote_path/src/main.js` on the server.
