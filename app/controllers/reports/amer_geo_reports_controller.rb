class Reports::AmerGeoReportsController < ApplicationController
    
  def index
    @show_element="reports-1"
  end

  def executive_dashboard
    @show_element="reports-1"
    # create list of available dates/dirs to pick from
    # don't show account names
    dirs = Dir.glob("#{RAILS_ROOT}/reports/[0-9][0-9][0-9][0-9]-[0-9][0-9]")
    #remove full path from glob
    @dirs = dirs.map!{|d|
      #extract the date from the end of the dir name.
      d[/\d{4}-\d{2}$/]#
      #works on windows, but not on hip-test (linux)  couldn't find reason.
      # d.delete("#{RAILS_ROOT}/reports/#{org_name}/")
    }
    unless params[:format].blank?
      storage_path = "#{RAILS_ROOT}/reports/#{params[:date]}"
      filename = "#{params[:date]}_Executive_Dashboard.#{params[:format].downcase}"

      case params[:format].downcase
      when "pdf"
        type="application/pdf"
      when 'csv'
        type='text/csv; charset=iso-8859-1; header=present'
      end
      puts "FILE: #{storage_path}/#{filename}"
      if File.exist?("#{storage_path}/#{filename}")
        send_file "#{storage_path}/#{filename}",
          :type =>type,
          :disposition => "attachment"
      else
        # the expected file doesn't exist
        flash[:error]= "The Executive Dashboard Report (#{params[:format]}) does not exist"
        redirect_to :action=>:executive_dashboard
      end
    end
  end

  def ooc_executive_dashboard
    
    # create list of available dates/dirs to pick from
    # don't show account names
    dirs = Dir.glob("#{RAILS_ROOT}/reports/[0-9][0-9][0-9][0-9]-[0-9][0-9]")
    #remove full path from glob
    @dirs = dirs.map!{|d|
      #extract the date from the end of the dir name.
      d[/\d{4}-\d{2}$/]#
      #works on windows, but not on hip-test (linux)  couldn't find reason.
      # d.delete("#{RAILS_ROOT}/reports/#{org_name}/")
    }
    unless params[:format].blank?

      case params[:format].downcase
      when "pdf"
        type="application/pdf"
        report_num='241P-01'
      when 'csv'
        type='text/csv; charset=iso-8859-1; header=present'
        report_num = '241C-01'
      end
      
      storage_path = "#{RAILS_ROOT}/reports/#{params[:date]}"
      filename = "#{params[:date]}_OOC_Executive_Dashboard_#{report_num}.#{params[:format].downcase}"
      
      if File.exist?("#{storage_path}/#{filename}")
        send_file "#{storage_path}/#{filename}",
          :type =>type,
          :disposition => "attachment"
      else
        # the expected file doesn't exist
        flash[:error]= "The OOC Executive Dashboard Report (#{params[:format]}) does not exist"
        redirect_to :action=>:ooc_executive_dashboard
      end
    end
  end
  
  def suppression_deviation_detail
    @show_element="reports-1"
    dirs = Dir.glob("#{RAILS_ROOT}/reports/[0-9][0-9][0-9][0-9]-[0-9][0-9]")
    dirs.map!{|d|
      d[/\d{4}-\d{2}$/]
    }

    @files = [{}]
    dirs.reverse_each do |dir|
      filename = "Suppression_Deviation_Detail_131C-01-#{dir}.csv"
      files = Dir.glob("#{RAILS_ROOT}/reports/#{dir}/#{filename}")
      unless files.empty?
        @files.push(:date=>dir, :files=>files.map{|f| "#{f.sub("#{RAILS_ROOT}/reports/#{dir}/",'')}"} )
      end
    end
  end

  def account_member
    send_file  "#{RAILS_ROOT}/reports/Account_Members.csv",
      :type=>'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment"
  end

  def get_file
    
    storage_path = "#{RAILS_ROOT}/reports/"
    send_file "#{storage_path}/#{params[:file]}",
      :disposition => "attachment"
  end

end
