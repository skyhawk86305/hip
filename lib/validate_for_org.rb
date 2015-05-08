class ValidateForOrg

  DEVIATION_LEVELS = [
      ["Compliant","allowed"],
      ["Info","info"],
      ["Information", "info"],
      ["Violation","high"],
      ["Warning","low"]
    ]

  def initialize(org_id_string)
    @org_id_string = org_id_string
    (l1_id, id) = org_id_string.split(',')
    @org = Org.service_hip.find(:first, :conditions => {:org_l1_id => l1_id, :org_id => id})
    @tool_names = Tool.hc_tool_names.map {|t| t.tool_name}
    load_asset_hash
  end

  def chip_id(chip_id)
    #validates if the chip_id is valid.  invalid chip_ids are reported in the
    #errors array, and returned.

    (l1_id, id) = org_id_string.split(',')
    errors = []

    unless chip_id.nil?
      if org.nil? || org.org_ecm_account_id.strip != chip_id
        errors << "Account chip_id  '#{chip_id}' not found in HIP, or doesn't match current account"
      end
    else
      errors << "No Chip Id provided"
    end
    return errors
  end

  def string(column, string, nilable)
    errors = nilable?(column,string, nilable)
    if errors.blank?
      begin
        String(string)
      rescue ArgumentError
        errors <<  "'#{string}' expected String for column #{column}"
      end
    end
    return errors
  end
    
  def tool_name(column, tool_name, nilable, host_name)
    errors = nilable?(column, tool_name, nilable)
    if errors.blank? && !tool_name.nil?
      if tool_names.find {|tn| tn.downcase == tool_name.downcase}.nil?
        errors << "'#{tool_name}' is not an accepted #{column}.  Accepted #{column}s are: '#{@tool_names.join("', '")}'"        
      end
      asset = asset_hash_find(host_name)
      if !asset.nil? && asset[:count] == 1 && !asset_hash_scan_tool_match?(host_name, tool_name)
        errors << "'#{tool_name}' does not match previous scan tool names in this file for host name #{host_name}"
      end
    end
   return errors
  end

  def int(column, int, nilable)
    errors = nilable?(column,int, nilable)
    if errors.blank?  && !int.nil?
      begin
        Integer(int)
      rescue ArgumentError
        errors <<  "'#{int}' expected Integer for column #{column}"
      end
    end
    return errors
  end

  def scan_timestamp(column, date, nilable, host_name)
    errors = nilable?(column,date, nilable)
    if errors.blank? && !date.nil?
      unless time = is_time?(date)
        errors <<  "'#{date}' is not a valid time for column #{column}, expecting time in the following format:  YYYY-MM-DD-hh:mm"
      end
      asset = asset_hash_find(host_name)
      if errors.size == 0 && !asset.nil? && asset[:count] == 1 # if we can't match on the host_name, ignore it since the host_name check will report errors
        if !asset_hash_scan_time_match?(host_name, time)
          errors << "'#{date}' does not match previous times in this file for the scan for host name #{host_name}"
        elsif time == asset[:last_scan_time]
          errors << "'#{date}' is at the same time as the last loaded scan time of #{asset[:last_scan_time].strftime("%Y-%m-%d-%H.%M.%S")} for host name #{host_name}. Uploaded scan time must be later than the last scan already loaded"
        elsif time < asset[:last_scan_time]
          errors << "'#{date}' is before the last loaded scan time of #{asset[:last_scan_time].strftime("%Y-%m-%d-%H.%M.%S")} for host name #{host_name}. Scans cannot be loaded out of order"
        elsif (time - 1.day) >= Time.zone.now
          errors << "'#{date}', #{column}, can not be in the future"
        end
      end
    end
    return errors
  end

  def deviation_level(column, string, nilable)
    errors = string(column, string, nilable)
    if errors.blank? && !string.nil? && transform_deviation_level(string).nil?
      errors << "'#{string}' is not allowed deviation level, must be one of: #{ValidateForOrg::DEVIATION_LEVELS.map{|i| i[0]}.join(", ")}"
    end
    return errors
  end

  def host_name(column, host_name_in, nilable)
    errors = nilable?(column,host_name_in, nilable)
    if errors.blank? && !host_name_in.nil?
      asset = asset_hash_find(host_name_in)
      if asset.nil?
        errors << "#{column} #{host_name_in} not found"
      elsif asset[:count] != 1
        errors << "#{column} #{host_name_in} matches more than one system (check for duplicate names in SysReg)"
      end
    end
    return errors
  end

  def is_time?(string)
    # Times are accepted in the following format:  yyyy mm dd HH MM SS
    # Where the seperator character between the numbers must be non numeric, and the seconds are optional
    if !(string =~ /^[0-9]{4}[^0-9]{1}[0-9]{2}[^0-9]{1}[0-9]{2}[^0-9]{1}[0-9]{2}[^0-9]{1}[0-9]{2}([^0-9]{1}[0-9]{2})?$/)
      return nil
    end
    year = string[0..3].to_i
    month = string[5..6].to_i
    date = string[8..9].to_i
    hour = string[11..12].to_i
    minute = string[14..15].to_i
    second = string[17..18].to_i || 00
    days_in_month_range = [1..31]*12
    days_in_month_range[3] = 1..30
    days_in_month_range[1] = leap_year?(year) ? (1..29) : (1..28)
    days_in_month_range[5] = 1..30
    days_in_month_range[8] = 1..30
    days_in_month_range[10] = 1..30
    if (1900..2100) === year && (1..12) === month && days_in_month_range[month-1] === date &&
      (0..23) === hour && (0..59) === minute && (0..59) === second
      return Time.utc(year, month, date, hour, minute, second, 0)
    else
      return nil
    end
  end

  alias :to_timestamp :is_time?

  def transform_deviation_level(string)
    tuple = ValidateForOrg::DEVIATION_LEVELS.find{|a,b| a.downcase == string.downcase}
    return tuple.nil? ? nil : tuple[1]
  end

  def to_scan_tool(name)
    tool_name =  tool_names.find {|tn| tn.downcase == name.downcase}
    return APP['mhc_translate_tool_names'][tool_name] || tool_name
  end

  def get_scan_timestamp(host_name)
    return asset_hash_find(host_name)[:scan_to_load_timestamp]
  end

  def get_scan_tool_name(host_name)
    return asset_hash_find(host_name)[:scan_tool_name]
  end


  ##########
  private
  ##########

  attr_reader :org_id_string, :tool_names, :assets, :org

  def load_asset_hash
    s_name = AssetScan.table_name
    assets = Asset.current.find(:all,
      :select => "a.tool_asset_id as asset_id, a.host_name,
        coalesce(max(s.scan_start_timestamp), '1900-01-01 00:00:00') as max_scan_timestamp",
      :joins => "as a left join #{s_name} as s on s.asset_id = a.tool_asset_id and s.scan_stop_timestamp > current_timestamp - 60 days",
      :group => "a.tool_asset_id, a.host_name",
      :conditions => "(a.org_l1_id, a.org_id) = (#{@org_id_string}) and a.system_status != 'decom'")
    @assets = {}
    assets.each do |a|
      full_host_name = a.host_name.downcase
      short_host_name = short_host_name(full_host_name)
      add_to_asset_hash(full_host_name, a)
      add_to_asset_hash(short_host_name, a) unless full_host_name == short_host_name
    end
    nil
  end

  def add_to_asset_hash(host_name, asset)
    if @assets.has_key?(host_name)
      @assets[host_name][:count] += 1
    else
      @assets[host_name] = {:host_name => host_name, 
        :count => 1, 
        :last_scan_time => Time.zone.parse(asset.max_scan_timestamp)
      }
    end
  end

  def asset_hash_find(host_name)
    return nil if host_name.nil?
    host_name = host_name.downcase
    return nil if @assets[host_name].nil?
    return @assets[host_name] if @assets[host_name][:count] == 1
    short_host_name = short_host_name(host_name)
    return nil if @assets[short_host_name].nil?
    return @assets[short_host_name] if @assets[short_host_name][:count] == 1
    return nil
  end

  def asset_hash_scan_time_match?(host_name, time)
    asset = asset_hash_find(host_name)
    if !asset.nil? && asset[:count] == 1
      if asset[:scan_to_load_timestamp].nil?
        @assets[asset[:host_name]][:scan_to_load_timestamp] = time
        return true
      else
        return asset[:scan_to_load_timestamp] == time
      end
    end
    return false
  end

  def asset_hash_scan_tool_match?(host_name, tool_name)
    asset = asset_hash_find(host_name)
    if !asset.nil? && asset[:count] == 1
      if asset[:scan_tool_name].nil?
        @assets[asset[:host_name]][:scan_tool_name] = to_scan_tool(tool_name)
        return true
      else
        return asset[:scan_tool_name] == to_scan_tool(tool_name)
      end
    end
    return false
  end

  def short_host_name(host_name)
    return host_name.gsub(/\..*$/, '')
  end

  def nilable?(column, value, nilable)
    if !nilable && (value.nil? || value.blank?)
      return ["'#{column}' can not be blank"]
    end
    return []
  end

  def leap_year?(year)
    year % 400 == 0 || (year % 100 != 0 && year % 4 == 0)
  end

end