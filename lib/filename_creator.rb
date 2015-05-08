# create a filename string with the given params
class FilenameCreator < File


  # return a filename string
  # available params:
  #   org_name - required
  #   group_name
  #   scan_type (scan_type.abbreviation)
  #   date - uses Time.now if nill
  #   report_num - required
  #   host_name
  #   extention - required
  #
  def self.filename(params)
    raise "Missing org_name" if params[:org_name].nil?
    raise "Missing report_num" if params[:report_num].nil?
    raise "Missing extention" if params[:extention].nil?

    "#{shrink(params[:org_name])}#{sep(params[:scan_type])}#{params[:scan_type]}#{sep(params[:host_name])}\
    #{shrink(params[:host_name])}#{sep(params[:group_name])}#{shrink(params[:group_name])}_\
    #{params[:report_num]}_#{check_date(params[:date])}#{sep(params[:unique])}#{params[:unique]}.#{params[:extention]}".gsub(/\s/,"")

  end

  private

  def self.sep(value)
    unless value.nil?
      "_"
    end
  end

  def self.shrink(value)
    re = /[^-.0-9a-zA-Z_]/
    unless value.nil?
      unless value.size > 20
        value.gsub(re,"_")
      else
        first=value[0..10]
        size=value.size
        last=value[(size-10)..size]
        "#{first}...#{last}".gsub(re,"_")
      end
    end
  end
  

  def self.check_date(date)
    if date.nil?
      Time.now.strftime("%Y-%m-%d")# no date given, return current date
    else
      date # return the date as given
    end
    
  end
end
