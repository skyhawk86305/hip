class LoadSample
  
  TIME_OFFSET = Time.now.beginning_of_month - Time.parse('2010-05-01 00:00:00')
  IGA = 8281
  CNH = 3568
  BELK = 3575
  IGA_ORGS_WITH_DATA = [
    8281,
    8282,
    8284,
    8289,
    8294,
    8296,
    8298,
    8299,
    8312,
    8314,
    8315,
    8345,
    8346,
    8347,
    8348,
    8349,
    8350,
    8352,
    8353,
    8354,
    8365,
    8366,
    8367,
    8372,
    8374,
    8376,
    8377,
    8383,
    8401,
    8405,
    8431
    ]
  
  def self.load()
    raise "load method of abstract class LoadScample called"
  end
  
  def self.nil_if_empty(string)
    return string == '' ? nil : string
  end
  
  def self.roll_date_forward(date_string, max_timestamp = nil)
    return nil if date_string.nil?
    rolled_time = (Time.parse(date_string + "UTC") + TIME_OFFSET).utc
  end
  
  def self.translate_tool_id(id)  # Translate between the origional test tool_ids and the new tool_ids
    return case id.to_s.to_i
    when 3 then 2   # Win HC Scanner Fusion 
    when 4 then 2   # Unix HC Scanner Fusion  
    when 10 then 4  # System Registration sysreg
    when 11 then 5  # Tech. Review Toolset TRT
    when 14 then 8  # VSA V2.5 HC vsa
    else id
    end
  end
  
end