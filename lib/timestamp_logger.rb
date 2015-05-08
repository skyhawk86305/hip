require 'active_support'
require 'fileutils'
class TimestampLogger < ActiveSupport::BufferedLogger
  
  # Define the same set of constants used by BufferedLogger in an array called SEVERITIES
  SEVERITIES = Severity.constants.inject([]) {|arr,c| arr[Severity.const_get(c)] = c; arr}
  
  def add(severity, message = nil, progname = nil, &block)
    return if @level > severity
    message = (message || (block && block.call) || progname).to_s
    level = SEVERITIES[severity] || "Unknown"
    now = Time.now
    current_thread = Thread.current
    user = current_thread.key?(:current_user) ? current_thread[:current_user].userid : 'N/A'
    message = "#{now.strftime("%Y-%m-%d %H:%M:%S")}.#{now.usec}: #{user}: #{level}: #{message}"
    message = "#{message}\n" unless message[-1] == ?\n
    buffer << message
    auto_flush
    message
  end
  
end