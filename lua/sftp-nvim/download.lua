local M = {}

local config = require('sftp-nvim.config')

-- Get the current working directory
local function get_cwd()
  return vim.fn.getcwd()
end

-- List remote files using ssh
local function list_remote_files(sftp_config)
  local cmd = "ssh "
  if sftp_config.port and sftp_config.port ~= 22 then
    cmd = cmd .. " -p " .. sftp_config.port
  end
  if sftp_config.use_key and sftp_config.key_path then
    cmd = cmd .. " -i " .. sftp_config.key_path
  end
  cmd = cmd .. " " .. sftp_config.username .. "@" .. sftp_config.host .. " 'find " .. sftp_config.remote_path .. " -type f'"
  if not sftp_config.use_key then
    cmd = "sshpass -p '" .. sftp_config.password .. "' " .. cmd
  end
  local result = vim.fn.systemlist(cmd)
  return result
end

-- Download selected file from remote
function M.download_file()
  local sftp_config = config.load_config()
  if not sftp_config then
    vim.notify("No SFTP config found. Run :SftpSetup first", vim.log.levels.ERROR)
    return
  end
  
  local files = list_remote_files(sftp_config)
  if not files or #files == 0 then
    vim.notify("No files found on remote.", vim.log.levels.ERROR)
    return
  end
  
  -- Simple selection: show numbered list and ask for input
  local choices = {}
  for i, f in ipairs(files) do
    table.insert(choices, i .. ": " .. f)
  end
  
  -- TODO: Replace this with a better UI (telescope, fzf, or floating window)
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
  if sftp_config.port and sftp_config.port ~= 22 then
    cmd = cmd .. " -P " .. sftp_config.port
  end
  if sftp_config.use_key and sftp_config.key_path then
    cmd = cmd .. " -i " .. sftp_config.key_path
  end
  
  if sftp_config.use_key then
    cmd = cmd .. " " .. sftp_config.username .. "@" .. sftp_config.host .. ":" .. remote_file .. " " .. local_file
  else
    cmd = "sshpass -p '" .. sftp_config.password .. "' " .. cmd .. " " .. sftp_config.username .. "@" .. sftp_config.host .. ":" .. remote_file .. " " .. local_file
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

return M
