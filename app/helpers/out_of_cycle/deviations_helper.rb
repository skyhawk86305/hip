module OutOfCycle::DeviationsHelper

  def grouped_options
    [
      ['Suppress Actions',
        [["Action","0"],['Suppress Selected','suppress'],["Suppress All","suppress_all"],["Remove Selected Suppressions","remove_suppression"]]],
      ['Validate Actions - Optional',
        [["Validate Selected","validate"],["Validate All","validate_all"],["Remove Selected Validation",'remove_validation']]]
    ]
  end

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
