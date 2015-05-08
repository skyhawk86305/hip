class HipMailer < ActionMailer::Base
  
  def offline_error(error_to, error_from, error_reply_to, instance, task_name, message)
    recipients  error_to
    from        error_from
    reply_to    error_reply_to
    subject     "HIP: Error processing offline task #{task_name} in instance #{instance}"
    #cc          array or list of people on carbon copy
    #bcc         array or list of people on blind carbon copy
    #sent_on     The date on which the message was sent, defaults to date used by delivery agant
    #content_type defaults to text/plain.  text/html could be useful
    body        :message => message, :instance => instance, :task_name => task_name
    RAILS_DEFAULT_LOGGER.error "#{subject}, #{message}"
  end
  
  def offline_message(msg_to, msg_from, msg_subject, message)
    recipients  msg_to
    from        msg_from
    subject     msg_subject
    body        :message => message
  end

  def offline_suppressions(msg_to, msg_from, msg_subject, message, id, params)
    json = JSON.parse(params)
    recipients  msg_to
    from        msg_from
    subject     msg_subject
    body        :message => message,:id=>id,:host =>json['host']
  end
  
  def mhc_status(msg_to,msg_from,msg_subject,message,id,host)
    recipients  msg_to
    from        msg_from
    subject     msg_subject
    body        :message => message,:id=>id,:host =>host
  end

  def cbn_notice(msg_to, msg_from, msg_subject, due_date, userids)
    content_type 'text/html'
    recipients  msg_to
    from        msg_from
    subject     msg_subject
    body        :userids => userids, :due_date => due_date
  end
end
