# config/initializers/pdfkit.rb
PDFKit.configure do |config|

  if RUBY_PLATFORM =~ /mswin32/
    config.wkhtmltopdf = 'C:/Program Files/wkhtmltopdf/wkhtmltopdf.exe'
  elsif RUBY_PLATFORM =~ /darwin/ # Mac OS X
    config.wkhtmltopdf = "#{%x{which wkhtmltopdf}.chomp}"
  else
    # the path is wrong on dev, so hard coding the path for now
    #config.wkhtmltopdf = "#{%x{which --skip-alias --skip-functions wkhtmltopdf}.chomp}"
     config.wkhtmltopdf = "/www/local/ruby-1.8.6/bin/wkhtmltopdf"
  end
  
  config.default_options = {
    :page_size => 'Legal',
    :print_media_type => true,
    :footer_center => "Page [page] of [topage]",
    :header_font_size=>"7"
  }
end
