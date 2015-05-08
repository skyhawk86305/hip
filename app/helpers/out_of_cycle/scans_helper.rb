module OutOfCycle::ScansHelper
  def remove_link(hide_element, as, row, page)
    if hide_element
      "remove label"
    elsif (as.system_scan_status=~/Labeled/)
      link_to_remote("remove label", 
                     :url=>{:controller => '/out_of_cycle/scans',
                            :action     => :destroy,
                            :option     => "remove_label",
                            :scan_id    => as.scan_id,
                            :page       => page,
                            :row        => row},
                     :method  => :delete,
                     :confirm => "Are you sure you want to remove this scan label?")
    end
  end
end
