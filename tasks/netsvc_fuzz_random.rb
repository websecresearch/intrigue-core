require 'socket'

###
### XXX - This module has not been extensively tested!
###

class NetsvcFuzzRandom < BaseTask

  def metadata
    { :version => "1.0",
      :name => "netsvc_fuzz_random",
      :pretty_name => "Fuzz a NetSvc with random data",
      :authors => ["jcran"],
      :description => "This task connects to a service and sends lots of random data.",
      :references => [],
      :allowed_types => ["NetSvc"],
      :example_entities => [
        {:type => "NetSvc", :attributes => {
          :ip_address => "104.237.133.83",
          :port => 8431,
          :protocol => "tcp"
          }
        }
      ],
      :allowed_options => [ ],
      :created_types => []
    }
  end

  ## Default method, subclasses must override this
  def run
    super

    # XXX - how to deal with accepting a complex object like this through
    # the UI? We'd need to know the entity structure, or set these up as options?

    port = _get_entity_attribute("port_num").to_i
    protocol = _get_entity_attribute "proto"
    ip_address = _get_entity_attribute "ip_address"

    @task_log.log "Port: #{port}"
    @task_log.log "Protocol: #{protocol}"
    @task_log.log "IP Address: #{ip_address}"
    
    # Check to make sure we have a sane target
    if protocol.downcase == "tcp"
      if ip_address and port
        s = TCPSocket.new(ip_address, port)
      else
        raise ArgumentError, "Missing IP Address and Port. Unable to open a socket."
      end
    else
      #raise ArgumentError, "Unknown Protocol. Unable to open a socket."
      s = UDPSocket.new
      s.connect(ip_address,port)
    end

    # Probe the port
    begin
      Timeout.timeout(10) do
        while true
          s.puts "#{(0...50).map{ ('a'..'z').to_a[rand(26)] }.join}\n"
        end
      end
    rescue Timeout::Error
      @task_log.log "Timed out"
    rescue Errno::EPIPE
      @task_log.log "Broken Pipe"
    rescue Errno::ECONNRESET
      @task_log.log "Connection Reset"
    end

    # Cleanup
    s.close
  end

end
