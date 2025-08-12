local M = {}

local config_file = ".sftp-config.json"

-- Default configuration
M.default_config = {
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
function M.load_config()
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

-- Setup SFTP configuration
function M.setup_config()
  local config = M.load_config() or M.default_config
  
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

-- Show current configuration
function M.show_config()
  local config = M.load_config()
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

return M
