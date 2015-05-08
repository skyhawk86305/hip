# load the hip config file
#APP = YAML.load_file("#{RAILS_ROOT}/config/hip_config.yml")[RAILS_ENV]

yaml = YAML.load(ERB.new(File.read("#{RAILS_ROOT}/config/hip_config.yml")).result)
APP= yaml[RAILS_ENV]

