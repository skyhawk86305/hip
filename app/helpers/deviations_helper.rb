module DeviationsHelper

  # With DeviationSearch#sql returning a validation_status, we don't need this function to determine it
  #def validation_status(deviation)
  #  unless deviation.suppress_id.blank?
  #    return "Suppressed"
  #  end
  #  unless deviation.scan_finding.blank?
  #    return deviation.scan_finding.result
  #  else
  #    return "Not Validated"
  #  end
  #
  #end

  def suppress_text(id)
    id.nil? ? "Select Suppression":"Remove Suppression"
  end

  def suppress_status(deviation)
    if deviation.suppress_id
      expires_at = deviation.suppress_end_timestamp.to_time
      if Time.now.between?(expires_at - 3.months, expires_at)
        :expires_soon
      else
        :current
      end
    elsif deviation.non_current_suppress_id
      :expired
    end
  end 
end
