class SessionFactory
  def self.create(ip, username, password, &error_handling)
    session = XenAPI::Session.new("https://#{ip}", &error_handling)
    session.login_with_password(username, password) 
  end
end
