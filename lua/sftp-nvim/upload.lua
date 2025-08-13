local M = {}

local config = require('sftp-nvim.config')

-- Get the current working directory
local function get_cwd()
  return vim.fn.getcwd()
end

-- Build SCP command for upload
local function build_scp_command(config, local_file, remote_file, is_directory)
  local cmd = "scp"
  
  -- Add recursive flag for directories
  if is_directory then
    cmd = cmd .. " -r"
  end
  
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
  local cmd = build_scp_command(sftp_config, current_file, remote_file, false)
  
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

-- List local directories and files in current working directory
local function list_local_items()
  local cwd = get_cwd()
  local items = {}
  
  -- Get all items in current directory
  local all_items = vim.fn.glob(cwd .. "/*", true, true)
  
  for _, item_path in ipairs(all_items) do
    local item_name = vim.fn.fnamemodify(item_path, ":t")
    local is_dir = vim.fn.isdirectory(item_path) == 1
    
    -- Skip hidden files and .sftp-config.json
    if not item_name:match("^%.") and item_name ~= ".sftp-config.json" then
      local display_name = (is_dir and "📁 " or "📄 ") .. item_name
      table.insert(items, {
        path = item_path,
        name = item_name,
        is_dir = is_dir,
        display = display_name
      })
    end
  end
  
  -- Sort: directories first, then files
  table.sort(items, function(a, b)
    if a.is_dir ~= b.is_dir then
      return a.is_dir -- directories first
    end
    return a.name < b.name -- alphabetical within same type
  end)
  
  return items
end

-- Check if remote directory exists and get confirmation for overwrite
local function check_remote_and_confirm(sftp_config, remote_path, item_name, is_directory)
  local item_type = is_directory and "directory" or "file"
  
  -- Build command to check if remote path exists
  local check_cmd = "ssh "
  if sftp_config.port and sftp_config.port ~= 22 then
    check_cmd = check_cmd .. " -p " .. sftp_config.port
  end
  if sftp_config.use_key and sftp_config.key_path then
    check_cmd = check_cmd .. " -i " .. sftp_config.key_path
  end
  
  check_cmd = check_cmd .. " " .. sftp_config.username .. "@" .. sftp_config.host .. " 'test -e " .. remote_path .. " && echo exists || echo not_exists'"
  if not sftp_config.use_key then
    check_cmd = "sshpass -p '" .. sftp_config.password .. "' " .. check_cmd
  end
  
  local result = vim.fn.system(check_cmd)
  local exists = string.match(result, "exists")
  
  if exists then
    -- Show confirmation dialog
    local choice = vim.fn.confirm(
      "Remote " .. item_type .. " '" .. remote_path .. "' already exists.\nDo you want to overwrite it?",
      "&Yes\n&No",
      2
    )
    return choice == 1
  end
  
  return true -- If doesn't exist, proceed
end

-- Upload selected directory or file
function M.upload_directory()
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
  
  local items = list_local_items()
  if not items or #items == 0 then
    vim.notify("No files or directories found in current directory.", vim.log.levels.ERROR)
    return
  end
  
  -- Use vim.ui.select for better UX
  vim.ui.select(items, {
    prompt = "Select file or directory to upload:",
    format_item = function(item)
      return item.display
    end
  }, function(choice)
    if not choice then
      return -- User cancelled
    end
    
    local cwd = get_cwd()
    local relative_path = choice.name
    
    -- Build remote path - for directories we want to upload to the parent and let SCP create the directory
    local remote_target
    if choice.is_dir then
      -- For directories, upload to remote_path and let SCP create the directory
      remote_target = sftp_config.remote_path
      if not string.match(remote_target, "/$") then
        remote_target = remote_target .. "/"
      end
      
      -- Check if remote directory exists and get confirmation
      local remote_dir_path = remote_target .. choice.name
      if not check_remote_and_confirm(sftp_config, remote_dir_path, choice.name, true) then
        vim.notify("Upload cancelled by user", vim.log.levels.INFO)
        return
      end
    else
      -- For files, build full remote path
      remote_target = sftp_config.remote_path
      if not string.match(remote_target, "/$") then
        remote_target = remote_target .. "/"
      end
      remote_target = remote_target .. relative_path
      
      -- Check if remote file exists and get confirmation
      if not check_remote_and_confirm(sftp_config, remote_target, choice.name, false) then
        vim.notify("Upload cancelled by user", vim.log.levels.INFO)
        return
      end
    end
    
    -- Build and execute command
    local cmd = build_scp_command(sftp_config, choice.path, remote_target, choice.is_dir)
    
    local item_type = choice.is_dir and "directory" or "file"
    vim.notify("Uploading " .. item_type .. " " .. choice.name .. "...", vim.log.levels.INFO)
    
    -- Execute command
    local result = vim.fn.system(cmd)
    local exit_code = vim.v.shell_error
    
    if exit_code == 0 then
      local final_remote_path = choice.is_dir and (remote_target .. choice.name) or remote_target
      vim.notify("Successfully uploaded " .. item_type .. " to " .. final_remote_path, vim.log.levels.INFO)
    else
      vim.notify("Upload failed: " .. result, vim.log.levels.ERROR)
    end
  end)
end

return M
