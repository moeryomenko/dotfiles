return {
  cmd = {'ansible-language-server', '--stdio'},
  filetypes = {'yaml.ansible'},
  root_markers = {'ansible.cfg', '.ansible-lint', 'playbook.yml', 'site.yml', '.git'},
  settings = {
    ansible = {
      python = {
        interpreterPath = "python3"
      },
      ansibleLint = {
        enabled = true,
        path = "ansible-lint"
      },
      executionEnvironment = {
        enabled = false
      }
    }
  }
}