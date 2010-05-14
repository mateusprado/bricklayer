require 'casclient'
require 'casclient/frameworks/rails/filter'
locale = I18n.locale.to_s
locale << '_BR' if locale == 'pt'

CASClient::Frameworks::Rails::Filter.configure(
  :cas_base_url => NephelaeConfig[:cas_base_url],
  :extra_attributes_session_key => :cas_extra_attributes,
  :login_url => "#{NephelaeConfig[:cas_base_url]}/login?locale=#{locale}"
)
