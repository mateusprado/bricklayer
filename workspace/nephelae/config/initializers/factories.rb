require 'factory_girl'
Dir["#{Rails.root}/db/factories/*.rb"].each do |file|
  require file
end
