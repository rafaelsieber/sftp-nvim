return {
  dir = "/home/rafael/Projetos/sftp-nvim", -- Use local directory
  name = "sftp-nvim",
  config = function()
    require("sftp-nvim").setup({
      -- Configuration options can be added here
    })
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
