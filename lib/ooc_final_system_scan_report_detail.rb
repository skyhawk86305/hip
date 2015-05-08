class OocFinalSystemScanReportDetail

  #
  # Disable calls to new from outside the class
  #
  private_class_method :new

  def self.get_report(org, group, scan, asset, add_to_title = '')
    report = new(org, group, scan, asset, add_to_title)
    report.get_report
  end

  def get_report
    return create_report
  end


  #########
  private
  #########

  def initialize(org, group, scan, asset, add_to_title)
    @org = org
    @group = group
    @scan = scan
    @asset = asset
    @add_to_title = add_to_title
  end
  
  def org_l1_id
    @org.org_l1_id
  end

  def org_id
    @org.org_id
  end

  def create_report

    results = OocDeviationSearch.find_by_scan(@scan, 10000)
    
    scan_start_timestamp = @scan.scan_start_timestamp
    html = StringIO.new

    html <<  "<html>"
    html <<  "<head>"
    html <<  "<title>OOC System Final Scan Details (#214P-01)</title>"
    html <<  "<style>"
    html <<  ".nobreak { page-break-inside: avoid;}"
    html <<  "</style>"
    html <<  "</head>"
    html <<  "<body>"
    html <<  "<p style='text-align:center'>"
    html <<  "<b>OOC System Final Scan Details (#A-214P-01)</b><br/>"
    html <<  "<b>Report Run Date:</b> #{Time.now.utc.strftime("%m/%d/%Y %H:%M")} UTC#{@add_to_title.empty? ? '' : " #{@add_to_title}"}<br/>"
    html <<  "</p>"
    html <<  "<p style='text-align:left'>"
    html <<  "<b>Account:</b> #{@org.org_name}<br/>"
    html <<  "<b>Customer ID:</b> #{@org.org_ecm_account_id}<br/>"
    html <<  "<b>Group Name:</b> #{@group.ooc_group_name}<br/>"
    html <<  "<b>Scan Type:</b> #{@scan.ooc_scan_type}<br/>"
    html <<  "<b>System Scan Date:</b> #{@scan.scan_start_timestamp}<br/>"
    html <<  "<b>System Name:</b> #{@asset.host_name}<br/>"
    html <<  "</p>"
    html <<  "<table style='border: 1px solid black;' rules='all' cellpadding='3px'>"

    html <<  "<tr>"
    html <<  "<th>Scan Tool</th>"
    html <<  "<th>Deviation Level</th>"
    html <<  "<th>Finding / Deviation Text</th>"
    html <<  "<th>Deviation Validation Group</th>"
    html <<  "<th>Suppression Classification</th>"
    html <<  "<th>Suppression Name</th>"
    html <<  "</tr>"

    if results.size == 0
      html << "<tr>"
      html << "<td valign='top' colspan=7><div class='nobreak'>HC Scanner found NO deviations</div></td>"
      html <<  "</tr>"
    end
    
    results.each do |result|
      html <<  "<tr>"
      html << "<td valign='top'><div class='nobreak'>#{result.manager_name.to_s}</div></td>"
      html << "<td valign='top'><div class='nobreak'>violation</div></td>"
      html << "<td valign='top'><div class='nobreak'>#{result.finding_text.to_s}</div></td>"
      html << "<td valign='top'><div class='nobreak'>#{result.cat_name.nil? ? result.sarm_cat_name.to_s : result.cat_name.to_s}</div></td>"
      html << "<td valign='top'><div class='nobreak'>#{result.suppress_class.to_s}</div></td>"
      html << "<td valign='top'><div class='nobreak'>#{result.suppress_name.to_s}</div></td>"
      html <<  "</tr>"
    end

    html <<  "</table>"
    html <<  "</body></html>"
    return html.string
  end

end