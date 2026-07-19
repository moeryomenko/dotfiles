return {
  cmd = {'helm_ls', 'serve'},
  filetypes = {'helm'},
  root_markers = {'Chart.yaml', '.git'},
  settings = {
    ['helm-ls'] = {
      yamlls = {
        path = 'yaml-language-server',
      },
    },
  },
}