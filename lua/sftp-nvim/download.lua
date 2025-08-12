local M = {}

local config = require('sftp-nvim.config')

-- Get the current working directory
local function get_cwd()
  return vim.fn.getcwd()
end

-- List remote files and folders using ssh
local function list_remote_items(sftp_config)
  local cmd = "ssh "
  if sftp_config.port and sftp_config.port ~= 22 then
    cmd = cmd .. " -p " .. sftp_config.port
  end
  if sftp_config.use_key and sftp_config.key_path then
    cmd = cmd .. " -i " .. sftp_config.key_path
  end
  
  -- List both files and directories with type indicator
  cmd = cmd .. " " .. sftp_config.username .. "@" .. sftp_config.host .. " 'find " .. sftp_config.remote_path .. " -printf \"%y %p\\n\"'"
  if not sftp_config.use_key then
    cmd = "sshpass -p '" .. sftp_config.password .. "' " .. cmd
  end
  
  local result = vim.fn.systemlist(cmd)
  local items = {}
  
  for _, line in ipairs(result) do
    local type_char, path = line:match("^(.) (.+)$")
    if type_char and path then
      local item = {
        path = path,
        is_dir = type_char == "d",
        display = (type_char == "d" and "📁 " or "📄 ") .. path
      }
      table.insert(items, item)
    end
  end
  
  -- Sort: directories first, then files
  table.sort(items, function(a, b)
    if a.is_dir ~= b.is_dir then
      return a.is_dir -- directories first
    end
    return a.path < b.path -- alphabetical within same type
  end)
  
  return items
end

-- Download selected file from remote
function M.download_file()
  local sftp_config = config.load_config()
  if not sftp_config then
    vim.notify("No SFTP config found. Run :SftpSetup first", vim.log.levels.ERROR)
    return
  end
  
  local items = list_remote_items(sftp_config)
  if not items or #items == 0 then
    vim.notify("No files or folders found on remote.", vim.log.levels.ERROR)
    return
  end
  
  -- Use vim.ui.select for better UX
  vim.ui.select(items, {
    prompt = "Select file or folder to download:",
    format_item = function(item)
      return item.display
    end
  }, function(choice)
    if not choice then
      return -- User cancelled
    end
    
    local cwd = get_cwd()
    local item_name = choice.path:match("[^/]+$")
    local local_path = cwd .. "/" .. item_name
    
    -- Build SCP command
    local cmd = "scp"
    if choice.is_dir then
      cmd = cmd .. " -r" -- Recursive for directories
    end
    
    if sftp_config.port and sftp_config.port ~= 22 then
      cmd = cmd .. " -P " .. sftp_config.port
    end
    if sftp_config.use_key and sftp_config.key_path then
      cmd = cmd .. " -i " .. sftp_config.key_path
    end
    
    if sftp_config.use_key then
      cmd = cmd .. " " .. sftp_config.username .. "@" .. sftp_config.host .. ":" .. choice.path .. " " .. local_path
    else
      cmd = "sshpass -p '" .. sftp_config.password .. "' " .. cmd .. " " .. sftp_config.username .. "@" .. sftp_config.host .. ":" .. choice.path .. " " .. local_path
    end
    
    local item_type = choice.is_dir and "folder" or "file"
    vim.notify("Downloading " .. item_type .. " " .. choice.path .. "...", vim.log.levels.INFO)
    
    local result = vim.fn.system(cmd)
    local exit_code = vim.v.shell_error
    
    if exit_code == 0 then
      vim.notify("Downloaded " .. item_type .. " to " .. local_path, vim.log.levels.INFO)
    else
      vim.notify("Download failed: " .. result, vim.log.levels.ERROR)
    end
  end)
end

return M
