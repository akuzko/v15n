V15n.setup do |config|
  # Define authentication strategy. Available options are :secret and :http_basic
  # default is :http_basic
  config.authentication_strategy = :http_basic

  # These options are used for :http_basic authentication strategy
  # follow /v15n/enable for prompting creditentials to enable visual translation
  config.username = 'interpreter'
  config.password = 'v15n_password'
  
  # authentication secret used for enabling v15n functionality
  # follow /v15n/enable?secret=#{config.secret} to enable visual translation
  # config.secret = <%= ActiveSupport::SecureRandom.hex(64).inspect %>

  # Setup db used for redis backend. default is 6
  config.redis_db = 6
end

I18n.backend = I18n::Backend::Chain.new(V15n.backend, I18n.backend)
