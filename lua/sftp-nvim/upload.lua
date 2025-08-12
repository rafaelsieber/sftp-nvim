local M = {}

local config = require('sftp-nvim.config')

-- Get the current working directory
local function get_cwd()
  return vim.fn.getcwd()
end

-- Build SCP command for upload
local function build_scp_command(config, local_file, remote_file)
  local cmd = "scp"
  
  -- Add port if not default
  if config.port and config.port ~= 22 then
    cmd = cmd .. " -P " .. config.port
  end
  
  -- Add key if specified
  if config.use_key and config.key_path then
    cmd = cmd .. " -i " .. config.key_path
  end
  
  -- Add source and destination
  if config.use_key then
    cmd = cmd .. " " .. local_file .. " " .. config.username .. "@" .. config.host .. ":" .. remote_file
  else
    -- For password authentication, we'll use sshpass if available
    cmd = "sshpass -p '" .. config.password .. "' " .. cmd .. " " .. local_file .. " " .. config.username .. "@" .. config.host .. ":" .. remote_file
  end
  
  return cmd
end

-- Upload current file
function M.upload_file()
  local sftp_config = config.load_config()
  if not sftp_config then
    vim.notify("No SFTP config found. Run :SftpSetup first", vim.log.levels.ERROR)
    return
  end
  
  -- Validate required fields
  if not sftp_config.host or sftp_config.host == "" then
    vim.notify("Host not configured", vim.log.levels.ERROR)
    return
  end
  
  if not sftp_config.username or sftp_config.username == "" then
    vim.notify("Username not configured", vim.log.levels.ERROR)
    return
  end
  
  -- Get current file
  local current_file = vim.fn.expand("%:p")
  if current_file == "" then
    vim.notify("No file is currently open", vim.log.levels.ERROR)
    return
  end
  
  -- Calculate relative path from cwd
  local cwd = get_cwd()
  local relative_path = string.gsub(current_file, "^" .. cwd .. "/", "")
  
  -- Build remote path
  local remote_file = sftp_config.remote_path
  if not string.match(remote_file, "/$") then
    remote_file = remote_file .. "/"
  end
  remote_file = remote_file .. relative_path
  
  -- Build and execute command
  local cmd = build_scp_command(sftp_config, current_file, remote_file)
  
  vim.notify("Uploading " .. relative_path .. "...", vim.log.levels.INFO)
  
  -- Execute command
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  
  if exit_code == 0 then
    vim.notify("File uploaded successfully to " .. remote_file, vim.log.levels.INFO)
  else
    vim.notify("Upload failed: " .. result, vim.log.levels.ERROR)
  end
end

return M
