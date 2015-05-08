# Be sure to restart your server when you modify this file

# require standard librarys
require 'csv'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '2.3.12' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

require 'timestamp_logger'
require 'pdfkit'

Rails::Initializer.run do |config|

  config.autoload_paths += %W( #{RAILS_ROOT}/vendor/prawn/lib )

  # Only load the plugins named here, in the order given (default is alphabetical).
  # :all can be used as a placeholder for all plugins not explicitly named
  # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

  # Skip frameworks you're not going to use. To use Rails without a database,
  # you must remove the Active Record framework.
  # config.frameworks -= [ :active_record, :active_resource, :action_mailer ]

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

  # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
  # Run "rake -D time" for a list of tasks for finding time zone names.
  config.time_zone = 'UTC'

  # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
  # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}')]
  # config.i18n.default_locale = :de
  
  # Configure a alternative logger, one that provides a timestamp
 config.log_path = File.join(RAILS_ROOT, 'log', "#{RAILS_ENV}.log")
 config.log_level = ENV['RAILS_ENV']=='production' ?  
   TimestampLogger::Severity::DEBUG :
   TimestampLogger::Severity::DEBUG
 config.logger = TimestampLogger.new(config.log_path, config.log_level)

  Encoding.default_external = Encoding::UTF_8
  Encoding.default_internal = Encoding::UTF_8

 end

 # The require for 'composite_primary_keys' has been moved to the SwareBase model to ensure it loads after active_record
 #require 'composite_primary_keys'
 require 'will_paginate'
 require 'weekdays'
 require 'zip/zip'
 require 'net/ldap'
 # The following is a monkey patch for Net::LDAP to work with IBM's ldap server which does not appear to support
 # paged searches in a manner compattable with Net::LDAP
 class Net::LDAP
  def paged_searches_supported?
    false
  end
 end
