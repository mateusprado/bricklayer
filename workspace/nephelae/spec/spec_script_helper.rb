def prepare_and_render_script(file_name, params)
  file_name = 'change_passwd'
  file = "#{SSHExecutor::scripts_folder}/#{file_name}.sh.erb"
  script = SSHExecutor::render_script(file, {:passwd_hash => 'abc-password-hash', :shadow_hash => 'abc-shadow-hash'})
end
