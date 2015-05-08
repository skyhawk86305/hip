# upload a file to the RAILS_ROOT/tmp dir
class DataFile

  def self.save(upload,directory="#{RAILS_ROOT}/tmp")
    begin
      name =  upload.original_filename
      # create the file path
      path = File.join(directory, name)
      # write the file
      File.open(path, "wb") { |f| f.write(upload.read) }
      return  path
    rescue Exception =>e
      e
    end
    
  end
end
