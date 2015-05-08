class LoadHipOocScanType
  
  def self.load  
    OocScanType.create(
      [
        {:ooc_scan_type => "transformation",      :file_name_abbreviation=>"TRF",     :ooc_group_type => "contract transform",  :ooc_scan_publish => 'n', :active_in_gui => 'y'},
        {:ooc_scan_type => "p-rem transformation",:file_name_abbreviation=>"PRTRF",   :ooc_group_type => "contract transform",  :ooc_scan_publish => 'y', :active_in_gui => 'y'},
        {:ooc_scan_type => "p-rem refresh",       :file_name_abbreviation=>"PRREF",   :ooc_group_type => "sec doc refresh",     :ooc_scan_publish => 'y', :active_in_gui => 'y'},
        {:ooc_scan_type => "refresh",             :file_name_abbreviation=>"REF",     :ooc_group_type => "sec doc refresh",     :ooc_scan_publish => 'n', :active_in_gui => 'y'},
        {:ooc_scan_type => "test",                :file_name_abbreviation=>"TEST",    :ooc_group_type => "specialized",         :ooc_scan_publish => 'n', :active_in_gui => 'y'},
        {:ooc_scan_type => "p-rem hc cycle",      :file_name_abbreviation=>"PRHC",    :ooc_group_type => "specialized",         :ooc_scan_publish => 'y', :active_in_gui => 'y'},
        {:ooc_scan_type => "mgmt request",        :file_name_abbreviation=>"MGMT",    :ooc_group_type => "specialized",         :ooc_scan_publish => 'n', :active_in_gui => 'y'},
        {:ooc_scan_type => "service activation",  :file_name_abbreviation=>"SA",      :ooc_group_type => "specialized",         :ooc_scan_publish => 'y', :active_in_gui => 'y'},
        {:ooc_scan_type => "exception hc cycle",  :file_name_abbreviation=>"EXPHC",   :ooc_group_type => "specialized",         :ooc_scan_publish => 'y', :active_in_gui => 'y'},
        #{:ooc_scan_type => "baseline settings",  :file_name_abbreviation=>"BASE",    :ooc_group_type => "transistion baseline",:ooc_scan_publish => 'n', :active_in_gui => 'y'},
      ])
  end
  
end