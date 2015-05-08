Time::DATE_FORMATS[:db] = lambda { |t| t.strftime("%Y-%m-%d %H:%M:%S.#{"%06d" % t.usec}") }
