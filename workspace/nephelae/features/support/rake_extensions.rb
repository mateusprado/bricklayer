require 'rake'
require 'rake/rdoctask'
require 'rake/testtask'
require 'tasks/rails'

class Cucumber::Rails::World
  def execute_rake(rake_task)
    raise "Rake task #{rake_task} doesn't exist" unless Rake::Task[rake_task]
    print output = capture_stdout { Rake::Task[rake_task].invoke }
    output
  end

  private
    def capture_stdout
      s = StringIO.new
      oldstdout = $stdout
      $stdout = s
      yield
      s.string
    ensure
      $stdout = oldstdout
    end
end
