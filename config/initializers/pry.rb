if %w(development test).include?(Rails.env)
  begin
    require 'pry'
  rescue LoadError
    puts "Couldn't load pry for development."
  end
end
