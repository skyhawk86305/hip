class ValidationGroupsController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search]

  def index
    @show_element="incycle"
    @deviation_search = DeviationSearch.new
  end

  def search
    require 'will_paginate/collection'
    session[:hc_group_id]=params[:deviation_search][:hc_group_id]
    session[:per_page]=params[:deviation_search][:per_page]
    session[:deviation_search]=params[:deviation_search]
    per_page=params[:deviation_search][:per_page].to_i
    page = (params[:page] ||= 1).to_i

    # build where to start and end the query
    rows_to=per_page*page.to_i
    if page==1
      rows_from=0
    else
      rows_from=(rows_to-per_page)+1
    end

    @deviations = WillPaginate::Collection.create(page, params[:deviation_search][:per_page]) do |pager|
      result = DeviationSearch.search(params[:deviation_search],rows_from,rows_to)
      # inject the result array into the paginated collection:
      pager.replace(result)

      #unless pager.total_entries
      # the pager didn't manage to guess the total count, do it manually
      pager.total_entries = result.size == 0 ? 0 : result.first[:count]
      #end
    end

    #@deviations = DeviationSearch.search(params[:deviation_search]).paginate \
    #  :page=>params[:page] , :per_page=>params[:deviation_search][:per_page]

    respond_to do |format|
      format.js {
        render :update do |page|
          page.replace_html 'result', :partial => 'result'
        end
      }
    end
  end

  def update
    label_option = params[:scan_findings][:option]

    case label_option
    when "selected" then
      update_category( params[:scan_findings][:scan_finding].values)
    when "remove"
      remove_category( params[:scan_findings][:scan_finding].values)
    when "all" then
      update_category_all
    end

    require 'will_paginate/collection'

    per_page=session[:deviation_search][:per_page].to_i
    page = (params[:page] ||= 1).to_i

    # build where to start and end the query
    rows_to=per_page*page.to_i
    if page==1
      rows_from=0
    else
      rows_from=(rows_to-per_page)+1
    end

    @deviations = WillPaginate::Collection.create(page, session[:deviation_search][:per_page]) do |pager|
      result = DeviationSearch.search(session[:deviation_search],rows_from,rows_to)
      # inject the result array into the paginated collection:
      pager.replace(result)

      #unless pager.total_entries
      # the pager didn't manage to guess the total count, do it manually
      pager.total_entries = result.size == 0 ? 0 : result.first[:count]
      #end
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

  def update_category(findings)
    finding_vids = findings.find_all {|f| f['selected']=='y' }.map{|f| f['finding_vid']}
    findings_to_update={:cat_name=>params[:scan_findings][:val_group],
      :finding_vids=>finding_vids.join(',')
    }
    bulk_update(findings_to_update)
  end

  def update_category_all
    per_page=1000
    # get the total number of findings.  first row has the counts
    deviations =DeviationSearch.search(session[:deviation_search],0,per_page)
    count = deviations.size == 0 ? 0 : deviations.first[:count]
    if count > 0
      if count < per_page
        per_page=count
      end
      pages = (count.to_f / per_page.to_f).ceil
      pages.times do |page|
        page +=1
        end_row=per_page
        start_row=0
        if session[:deviation_search][:val_group].downcase=="all"
          end_row=per_page*page
          start_row=(end_row-per_page)+1
        end
        # first page was setup already
        unless page==1
          deviations =DeviationSearch.search(session[:deviation_search],start_row,end_row)
          count = deviations.size == 0 ? 0 : deviations.first[:count] 
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
  
  def remove_category(findings)
    finding_vids = findings.find_all {|f| f['selected']=='y' }.map{|f| f['finding_vid']}
    findings_to_update={      :finding_vids=>finding_vids.join(',')}
    FactScan.update_all("cat_name=null","finding_vid IN (#{findings_to_update[:finding_vids]})")
  end

  def bulk_update(findings)
    #$stderr.puts "findings #{findings}"
    FactScan.update_all("cat_name='#{findings[:cat_name]}'","finding_vid IN (#{findings[:finding_vids]})")
  end
end
