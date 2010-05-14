module NephelaeConfig
  def self.[](name)
    configuration[name.to_s]
  end

  def self.complete?
    example_configuration = load_file('nephelae.yml.example')[RAILS_ENV]
    configuration.check_missing_keys(example_configuration).empty?
  end
  
 private
  def self.configuration
    @configuration ||= load_file[RAILS_ENV]
  end

  def self.load_file(file_name = 'nephelae.yml')
    YAML.load_file("#{Rails.root}/config/#{file_name}")
  end
end
