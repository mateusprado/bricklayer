Before('@installation') do
  start_queue
  execute_rake 'nephelae:consumers:start:all'
end

After('@installation') do
  execute_rake 'nephelae:consumers:stop:all'
  stop_queue
end

def start_queue
  FileUtils.rm_rf NephelaeConfig[:queue_server][:database_dir]
  @queue_server = IO.popen(NephelaeConfig[:queue_server][:start_script])
  sleep 30
end

def stop_queue
  Process.kill "HUP", @queue_server.pid
  @queue_server.close
  FileUtils.rm_rf NephelaeConfig[:queue_server][:database_dir]
end

Before('@notxn') do
  DatabaseCleaner.clean
  DatabaseCleaner.strategy = :truncation
  DatabaseCleaner.start
end

Before do
  DatabaseCleaner.start
end

After do
  DatabaseCleaner.clean
end

After('@notxn') do
  DatabaseCleaner.clean
  DatabaseCleaner.strategy = :transaction
  DatabaseCleaner.start
end
