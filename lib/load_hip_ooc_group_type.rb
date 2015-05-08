class LoadHipOocGroupType

  def self.load
    OocGroupType.create(
    [
      {:ooc_group_type => "contract transform", :ooc_group_type_desc => "Contract Transformation Scans"},
      {:ooc_group_type => "sec doc refresh", :ooc_group_type_desc => "Security Document Refresh Scans"},
      #{:ooc_group_type => "transition baseline", :ooc_group_type_desc => "Transition Scans"},
      {:ooc_group_type => "specialized", :ooc_group_type_desc => "Scan Types That Are Not Tied To A Contract Event"},
      ])
    end

  end