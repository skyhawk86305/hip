class LoadOrgIdSample < LoadSample

  def self.load
    if RAILS_ENV == 'development' || RAILS_ENV == 'test'
      OrgId.transaction do
        filename = File.join(RAILS_ROOT, "db", "sample_sware_data","DIM_COMM_ORG_IDS.csv")
        CSV.foreach(filename) do |row|
          OrgId.create(
          :org_id => row[0]
          )
        end
      end
    end
  end

end
