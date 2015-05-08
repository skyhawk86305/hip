class DeviationsController < ApplicationController
  before_filter :select_org
  before_filter :has_current_org_id
  before_filter :edit_authorization ,:except=>[:index,:search]

  def index
    session[:publish_scan_search]=nil
    session[:scan_search]=nil
    session[:asset_search]=nil
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

    # @deviations = DeviationSearch.search(params[:deviation_search],rows_from,rows_to).paginate \
    #  :page=>params[:page] , :per_page=>params[:deviation_search][:per_page],:total_entries=>1000
    
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
    when "remove_suppression" then
      remove_suppressions(params[:scan_findings][:scan_finding].values)
    when "remove_all_suppressions" then
      pager(:remove_suppressions,session[:deviation_search][:val_status],1000)
    when "suppress_all"
      pager(:suppress_deviations,session[:deviation_search][:val_status],500)
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
      pager.total_entries = result.first[:count]
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

  def suppress_deviations(deviations)

    RAILS_DEFAULT_LOGGER.debug "deviations[0].class.name:  #{deviations[0].class.name}"
    # What comes in look like an array of hashes.  They are really either ActiveRecord objects that are the result of
    # a DeviationSearch.search which are DeviationSearch objects, or a HashWithIndifferentAccess containing keys of
    # finding_id and suppress_id
    
    validations = []
    deviations.each do |d|
      finding_id = d['finding_id']
      # used to handle updating all in result where selected is always 'n'
      #selected = d['selected'].nil? ? 'y': d['selected']
      suppress_id = params[:scan_findings][:suppress_id]
      unless finding_id.blank?
        existing = SuppressFinding.find_by_finding_id(d['finding_id'])
        if existing.nil? and !suppress_id.blank?
          validations << {
            :finding_id => finding_id,
            :suppress_id=> suppress_id,
            :lu_userid  => current_user.userid,
          }
        end
      end
    end
    SuppressFinding.create_all! validations
  end
  
  def remove_suppressions(deviations)
    finding_ids = deviations.find_all {|f| !f['finding_id'].blank?}.map{|f| f['finding_id']}
    SuppressFinding.delete_all("finding_id IN (#{finding_ids.join(",")})")
  end
  
  # method is the method to call to update all records
  # filter_param is the value to test "all" against.  If the filter is all, the
  # paging sequence changes
  # per_page is the number of records to process at one time.
  def pager(method,filter_param,per_page=500)
    
    deviations = DeviationSearch.search(session[:deviation_search],0,per_page)
    count = deviations.first[:count]
    if count > 0
      pages = (count / per_page.to_f).ceil
      if count < per_page
        per_page=count
      end
      pages.times do |page|
        page +=1
        end_row=per_page
        start_row=0
        if filter_param.downcase=='all'
          end_row=per_page*page
          start_row=(end_row-per_page)+1
        end
#        $stderr.puts "pager: #{page} | #{pages} | #{start_row} | #{end_row} | #{count}"
        unless page==1
          SwareBase.uncached do
            deviations = DeviationSearch.search(session[:deviation_search],start_row,end_row)
          end
        end
        send(method, deviations)
      end
    end
  end
end
