" SFTP-Nvim Plugin
" Simple SFTP file upload plugin for Neovim

if exists('g:loaded_sftp_nvim')
  finish
endif
let g:loaded_sftp_nvim = 1

" Plugin commands
command! SftpSetup lua require('sftp-nvim').setup_config()
command! SftpUpload lua require('sftp-nvim').upload_file()
command! SftpConfig lua require('sftp-nvim').show_config()
command! SftpDownload lua require('sftp-nvim').download_file()
