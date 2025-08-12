local M = {}

-- Import modules
local config = require('sftp-nvim.config')
local upload = require('sftp-nvim.upload')
local download = require('sftp-nvim.download')

-- Expose module functions
M.setup_config = config.setup_config
M.show_config = config.show_config
M.upload_file = upload.upload_file
M.download_file = download.download_file

-- Setup plugin
function M.setup(opts)
  opts = opts or {}
  
  -- Create user commands
  vim.api.nvim_create_user_command("SftpSetup", M.setup_config, {})
  vim.api.nvim_create_user_command("SftpUpload", M.upload_file, {})
  vim.api.nvim_create_user_command("SftpConfig", M.show_config, {})
  vim.api.nvim_create_user_command("SftpDownload", M.download_file, {})
end

return M
