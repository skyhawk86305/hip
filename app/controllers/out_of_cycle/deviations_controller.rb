class OutOfCycle::DeviationsController < ApplicationController
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

      #unless pager.total_entries
      # the pager didn't manage to guess the total count, do it manually
      pager.total_entries = result.size == 0 ? 0 : result.first.count
      #end
    end
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
    when "suppress" then
      suppress_deviations(params[:scan_findings][:scan_finding].values)
    when "suppress_all" then
      pager(:suppress_deviations,session[:ooc_deviation_search][:val_status],500)
    when "remove_suppression" then
      remove_suppression(params[:scan_findings][:scan_finding].values)
    when "remove_all_suppressions" then
      pager(:remove_suppression,session[:ooc_deviation_search][:val_status],1000)
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

  def suppress_deviations(deviations)

    RAILS_DEFAULT_LOGGER.debug "deviations[0].class.name:  #{deviations[0].class.name}"
    # What comes in look like an array of hashes.  They are really either ActiveRecord objects that are the result of
    # a DeviationSearch.search which are DeviationSearch objects, or a HashWithIndifferentAccess containing keys of
    # finding_id and suppress_id
    # suppress_id is the selection from the user to suppress_all deviations from the filter.

    validations = []
    deviations.each do |d|
      finding_id = d['finding_id']
      suppress_id=params[:scan_findings][:suppress_id]
      # selected = d['selected'].nil? ? 'y':d['selected']
      unless finding_id.blank?
        # suppress_id is the suppression to apply, supplied by the user.
        #existing =   SuppressFinding.find_by_finding_id(d['finding_id'])
        # d['suppress_id'] is an existing suppression
        if d['suppress_id'].blank? and !suppress_id.blank?
          validations << {
            :finding_id => finding_id,
            :suppress_id=> suppress_id,
            :lu_userid  => current_user.userid,
          }
          # elsif existing and suppress_id.blank?
          #   existing.destroy
        end
        #end
      end
    end
    SuppressFinding.create_all! validations
  end
  
  def remove_suppression(deviations)
    finding_ids = deviations.find_all {|f| !f['finding_id'].blank? }.map{|f| f['finding_id']}
    SuppressFinding.delete_all("finding_id IN (#{finding_ids.join(",")})")
  end

  # method is the method to call to update all records
  # filter_param is the value to test "all" against.  If the filter is all, the
  # paging sequence changes
  # per_page is the number of records to process at one time.
  def pager(method,filter_param,per_page=500)
    session[:ooc_deviation_search][:row_from]=0
    session[:ooc_deviation_search][:row_to]=per_page
    deviations = OocDeviationSearch.search(session[:ooc_deviation_search])
    count = deviations.size == 0 ? 0 : deviations.first.count
    if count > 0
      pages = (count / per_page.to_f).ceil
      if count < per_page
        per_page=count
      end
      pages.times do |page|
        page +=1
        session[:ooc_deviation_search][:row_from]=0
        session[:ooc_deviation_search][:row_to]=per_page
        if filter_param.downcase=='all'
          row_to=per_page*page
          row_from=(row_to-per_page)+1
          session[:ooc_deviation_search][:row_from]=row_from
          session[:ooc_deviation_search][:row_to]=row_to
        end
        #$stderr.puts "pager: #{page} | #{pages} | #{session[:ooc_deviation_search][:row_from]} |\
        ##{session[:ooc_deviation_search][:row_to]} | #{count}"
        unless page==1
          SwareBase.uncached do
          deviations = OocDeviationSearch.search(session[:ooc_deviation_search])
          count = deviations.size == 0 ? 0 : deviations.first.count
          end
        end
        send(method, deviations)
      end
    end
  end
  def search_params(params)
    {:per_page => params[:per_page],
      :org_id=>params[:org_id],
      :ooc_group_id=>params[:ooc_group_id],
      :ooc_scan_type=>params[:ooc_scan_type],
      :ooc_group_type=>params[:ooc_group_type],
      :host_name=>params[:host_name],
      :ip_address=>params[:ip_address],
      :os=>params[:os],
      :system_status=>params[:system_status],
      :val_group => params[:val_group],
      :vuln_title => params[:vuln_title],
      :vuln_text => params[:vuln_text],
      :deviation_level => params[:deviation_level],
      :val_status => params[:val_status],
      :suppress_status=>params[:suppress_status],
      :suppress_id=>params[:suppress_id]
    }
  end
end
