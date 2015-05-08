# Settings specified here will take precedence over those in config/environment.rb

# The production environment is meant for finished, "live" apps.
# Code is not reloaded between requests
config.cache_classes = true

# Full error reports are disabled and caching is turned on
config.action_controller.consider_all_requests_local = true
config.action_controller.perform_caching             = true
config.action_view.cache_template_loading            = true

# See everything in the log (default is :info)
config.log_level = :debug

# Use a different logger for distributed setups
# config.logger = SyslogLogger.new

# Use a different cache store in production
# config.cache_store = :mem_cache_store

# Enable serving of images, stylesheets, and javascripts from an asset server
# config.action_controller.asset_host = "http://assets.example.com"

# Disable delivery errors, bad email addresses will be ignored
# config.action_mailer.raise_delivery_errors = false

# Enable threaded mode
# config.threadsafe!

# Don't care if the mailer can't send
#config.action_mailer.raise_delivery_errors = false
config.action_mailer.raise_delivery_errors = true

# Set delivery method to :smtp, :sendmail or :test
config.action_mailer.delivery_method = :smtp

# These options are only needed if you choose smtp delivery
config.action_mailer.smtp_settings = {
  :address          => "us.ibm.com",
  #:port            => 25,
  :domain          => "us.ibm.com"
  #:authentication  => :login,
  #:username        => "www",
  #:password        => 'secret'
}

# Setup action mailer for test deliveries
#config.action_mailer.delivery_method = :test
#config.action_mailer.perform_deliveries = true
#config.action_mailer.deliveries = []