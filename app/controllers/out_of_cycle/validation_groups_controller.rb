class OutOfCycle::ValidationGroupsController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search,:group_scan_lists]

  def index
    @show_element="outofcycle"
  end

  def search
    session[:per_page]=params[:per_page]
    session[:ooc_group_type] = params[:ooc_group_type]
    session[:ooc_group_id] = params[:ooc_group_id]
    session[:ooc_scan_type] = params[:ooc_scan_type]
    session[:ooc_deviation_search]=search_params(params)
    require 'will_paginate/collection'
    per_page=params[:per_page].to_i
    page = (params[:page] ||= 1).to_i

    # build where to start and end the query
    rows_to=per_page*page.to_i
    if page==1
      rows_from=0
    else
      rows_from=(rows_to-per_page)+1
    end
    session[:ooc_deviation_search][:row_from]=rows_from
    session[:ooc_deviation_search][:row_to]=rows_to
    @deviations = WillPaginate::Collection.create(page, session[:ooc_deviation_search][:per_page]) do |pager|
      result = OocDeviationSearch.search(session[:ooc_deviation_search])
      # inject the result array into the paginated collection:
      pager.replace(result)
      pager.total_entries = result.size == 0 ? 0 : result.first.count
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html("result", :partial=>"result")
        end
      }
    end
  end

  def update
    label_option = params[:scan_findings][:option]

    case label_option
    when "selected" then
      update_category( params[:scan_findings][:scan_finding].values,params[:scan_findings][:val_group])
    when "remove"
      remove_category( params[:scan_findings][:scan_finding].values)
    when "all" then
      update_category_all
    end
    
    require 'will_paginate/collection'

    per_page=session[:ooc_deviation_search][:per_page].to_i
    page = (params[:page] ||= 1).to_i

    # build where to start and end the query
    rows_to=per_page*page.to_i
    if page==1
      rows_from=0
    else
      rows_from=(rows_to-per_page)+1
    end
    session[:ooc_deviation_search][:row_from]=rows_from
    session[:ooc_deviation_search][:row_to]=rows_to
    @deviations = WillPaginate::Collection.create(page, session[:ooc_deviation_search][:per_page]) do |pager|
      result = OocDeviationSearch.search(session[:ooc_deviation_search])
      # inject the result array into the paginated collection:
      pager.replace(result)
      pager.total_entries = result.size == 0 ? 0 : result.first.count
    end
    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html("result", :partial=>"result")
        end
      }
    end
  end
  
  private
  # update selected records
  def update_category(findings,val_group)
    finding_vids = findings.find_all {|f| f['selected']=='y' }.map{|f| f['finding_vid']}
    findings_to_update={:cat_name=>val_group,
      :finding_vids=>finding_vids.join(',')
    }
    bulk_update(findings_to_update)
  end
  # update all records in the filter
  def update_category_all
    per_page=1000
    page=1
    # suppress all findings from the previously executed filter
    session[:ooc_deviation_search][:row_from]=0
    session[:ooc_deviation_search][:row_to]=per_page

    #
    # get the total number of findings.  first row has the counts
    deviations =OocDeviationSearch.search(session[:ooc_deviation_search])
    count = deviations.size == 0 ? 0 : deviations.first.count

    # if the user didn't select a validation group (All), the start and
    # end rows are always the same.
    # otherwise keep track of the rows and page through them.
    if count > 0
      pages = (count / per_page.to_f).ceil
      if count < per_page
        per_page=count
      end
      pages.times do |page|
        page+=1
        end_row=per_page
        start_row=0
        if session[:ooc_deviation_search][:val_group].downcase=="all"
          end_row=per_page*page
          start_row=(end_row-per_page)+1
        end
        # first page was setup already
 
        unless page==1       
          session[:ooc_deviation_search][:row_from]=start_row
          session[:ooc_deviation_search][:row_to]=end_row
          deviations =OocDeviationSearch.search(session[:ooc_deviation_search])
          count = deviations.size == 0 ? 0 : deviations.first.count 
        end
        $stderr.puts "pager1: #{page} | #{pages} | #{start_row} | #{end_row} | #{count}"
        finding_vids = deviations.find_all{|d| !d.finding_vid.nil?}.map{ |d| d.finding_vid }
        findings={:cat_name=>params[:scan_findings][:val_group],
          :finding_vids=>finding_vids.join(',')
        }
        bulk_update(findings)
      end
    end
  end
  
  def bulk_update(findings)
    FactScan.update_all("cat_name='#{findings[:cat_name]}'","finding_vid IN (#{findings[:finding_vids]})")
  end

  def remove_category(findings)
    finding_vids = findings.find_all {|f| f['selected']=='y' }.map{|f| f['finding_vid']}
    findings_to_update={      :finding_vids=>finding_vids.join(',')}
    FactScan.update_all("cat_name=null","finding_vid IN (#{findings_to_update[:finding_vids]})")
  end

  def search_params(params)
    {:per_page => params[:per_page],
      :org_id=>params[:org_id],
      :ooc_group_id=>params[:ooc_group_id],
      :ooc_scan_type=>params[:ooc_scan_type],
      :ooc_group_type=>params[:ooc_group_type],
      :host_name=>params[:host_name],
      :ip_string_list=>params[:ip_string_list],
      :os=>params[:os],
      :system_status=>params[:system_status],
      :val_group => params[:val_group],
      :vuln_title => params[:vuln_title],
      :vuln_text => params[:vuln_text],
      :deviation_level => params[:deviation_level],
      :val_status => params[:val_status],
      :suppress_id=>params[:suppress_id]


    }
  end
end
