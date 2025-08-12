local M = {}

local config_file = ".sftp-config.json"

-- Default configuration
local default_config = {
  host = "",
  port = 22,
  username = "",
  password = "",
  remote_path = "/",
  use_key = false,
  key_path = "~/.ssh/id_rsa"
}

-- Get the current working directory
local function get_cwd()
  return vim.fn.getcwd()
end

-- Get the config file path
local function get_config_path()
  return get_cwd() .. "/" .. config_file
end

-- Check if config file exists
local function config_exists()
  local file = io.open(get_config_path(), "r")
  if file then
    file:close()
    return true
  end
  return false
end

-- Load configuration from file
local function load_config()
  if not config_exists() then
    return nil
  end
  
  local file = io.open(get_config_path(), "r")
  if not file then
    return nil
  end
  
  local content = file:read("*all")
  file:close()
  
  local ok, config = pcall(vim.json.decode, content)
  if not ok then
    vim.notify("Error parsing SFTP config file", vim.log.levels.ERROR)
    return nil
  end
  
  return config
end

-- Save configuration to file
local function save_config(config)
  local file = io.open(get_config_path(), "w")
  if not file then
    vim.notify("Could not create config file", vim.log.levels.ERROR)
    return false
  end
  
  local json_content = vim.json.encode(config)
  file:write(json_content)
  file:close()
  
  vim.notify("SFTP config saved to " .. config_file, vim.log.levels.INFO)
  return true
end

-- Build SCP command
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

-- Setup SFTP configuration
function M.setup_config()
  local config = load_config() or default_config
  
  -- Create input fields
  local function get_input(prompt, default)
    return vim.fn.input(prompt .. " [" .. (default or "") .. "]: ")
  end
  
  local new_config = {}
  
  -- Get configuration from user
  new_config.host = get_input("Host", config.host)
  if new_config.host == "" then new_config.host = config.host end
  
  local port_input = get_input("Port", tostring(config.port))
  new_config.port = tonumber(port_input) or config.port
  
  new_config.username = get_input("Username", config.username)
  if new_config.username == "" then new_config.username = config.username end
  
  new_config.remote_path = get_input("Remote path", config.remote_path)
  if new_config.remote_path == "" then new_config.remote_path = config.remote_path end
  
  -- Authentication method
  local auth_method = get_input("Authentication (key/password)", config.use_key and "key" or "password")
  new_config.use_key = auth_method == "key"
  
  if new_config.use_key then
    new_config.key_path = get_input("SSH Key path", config.key_path)
    if new_config.key_path == "" then new_config.key_path = config.key_path end
  else
    new_config.password = get_input("Password", "")
    if new_config.password == "" then new_config.password = config.password end
  end
  
  -- Save configuration
  save_config(new_config)
end

-- Upload current file
function M.upload_file()
  local config = load_config()
  if not config then
    vim.notify("No SFTP config found. Run :SftpSetup first", vim.log.levels.ERROR)
    return
  end
  
  -- Validate required fields
  if not config.host or config.host == "" then
    vim.notify("Host not configured", vim.log.levels.ERROR)
    return
  end
  
  if not config.username or config.username == "" then
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
  local remote_file = config.remote_path
  if not string.match(remote_file, "/$") then
    remote_file = remote_file .. "/"
  end
  remote_file = remote_file .. relative_path
  
  -- Build and execute command
  local cmd = build_scp_command(config, current_file, remote_file)
  
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

-- List remote files using ssh
local function list_remote_files(config)
  local cmd = "ssh "
  if config.port and config.port ~= 22 then
    cmd = cmd .. " -p " .. config.port
  end
  if config.use_key and config.key_path then
    cmd = cmd .. " -i " .. config.key_path
  end
  cmd = cmd .. " " .. config.username .. "@" .. config.host .. " 'find " .. config.remote_path .. " -type f'"
  if not config.use_key then
    cmd = "sshpass -p '" .. config.password .. "' " .. cmd
  end
  local result = vim.fn.systemlist(cmd)
  return result
end

-- Download selected file from remote
function M.download_file()
  local config = load_config()
  if not config then
    vim.notify("No SFTP config found. Run :SftpSetup first", vim.log.levels.ERROR)
    return
  end
  local files = list_remote_files(config)
  if not files or #files == 0 then
    vim.notify("No files found on remote.", vim.log.levels.ERROR)
    return
  end
  -- Simple selection: show numbered list and ask for input
  local choices = {}
  for i, f in ipairs(files) do
    table.insert(choices, i .. ": " .. f)
  end
  vim.notify("Remote files:\n" .. table.concat(choices, "\n"), vim.log.levels.INFO)
  local idx = tonumber(vim.fn.input("Select file number to download: "))
  if not idx or not files[idx] then
    vim.notify("Invalid selection.", vim.log.levels.ERROR)
    return
  end
  local remote_file = files[idx]
  local cwd = get_cwd()
  local filename = remote_file:match("[^/]+$")
  local local_file = cwd .. "/" .. filename
  -- Build SCP command (reverse direction)
  local cmd = "scp"
  if config.port and config.port ~= 22 then
    cmd = cmd .. " -P " .. config.port
  end
  if config.use_key and config.key_path then
    cmd = cmd .. " -i " .. config.key_path
  end
  if config.use_key then
    cmd = cmd .. " " .. config.username .. "@" .. config.host .. ":" .. remote_file .. " " .. local_file
  else
    cmd = "sshpass -p '" .. config.password .. "' " .. cmd .. " " .. config.username .. "@" .. config.host .. ":" .. remote_file .. " " .. local_file
  end
  vim.notify("Downloading " .. remote_file .. "...", vim.log.levels.INFO)
  local result = vim.fn.system(cmd)
  local exit_code = vim.v.shell_error
  if exit_code == 0 then
    vim.notify("Downloaded to " .. local_file, vim.log.levels.INFO)
  else
    vim.notify("Download failed: " .. result, vim.log.levels.ERROR)
  end
end

-- Show current configuration
function M.show_config()
  local config = load_config()
  if not config then
    vim.notify("No SFTP config found", vim.log.levels.WARN)
    return
  end
  
  local lines = {
    "SFTP Configuration:",
    "Host: " .. (config.host or ""),
    "Port: " .. (config.port or "22"),
    "Username: " .. (config.username or ""),
    "Remote path: " .. (config.remote_path or "/"),
    "Authentication: " .. (config.use_key and "SSH Key" or "Password"),
  }
  
  if config.use_key then
    table.insert(lines, "Key path: " .. (config.key_path or ""))
  end
  
  vim.notify(table.concat(lines, "\n"), vim.log.levels.INFO)
end

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
