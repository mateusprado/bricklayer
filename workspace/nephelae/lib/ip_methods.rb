module IpMethods
  IP_PATTERN = /\A(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)(?:\.(?:25[0-5]|(?:2[0-4]|1\d|[1-9])?\d)){3}\z/
  
  def self.from_bin(ip_bin)
     "#{ip_bin >> 24}.#{(ip_bin >> 16) & 255}.#{(ip_bin >> 8) & 255}.#{ip_bin & 255}"
  end
  
  def self.to_bin(ip)
    ip_bin = 0
    shift = 24
    ip.split('.').each do |part|
      ip_bin += (part.to_i << shift)
      shift -= 8
    end
    ip_bin
  end
  
  def network
    IpMethods.from_bin(network_bin)
  end
  
  def net_mask
	  IpMethods.from_bin(mask_bin)
  end
  
  def default_gateway
    IpMethods.from_bin(network_bin+1)
  end
  
  def broadcast
    IpMethods.from_bin(broadcast_bin)
  end
  
  def generate_ips
    ips = []
    (network_bin+1..broadcast_bin-1).each {|ip_bin| ips << IpMethods.from_bin(ip_bin)}
    ips
  end
  
  def to_bin
    IpMethods.to_bin(address)
  end
  
  def mask_bin
    umask = 0
		range = 32 - mask
		(0..mask-1).each {|i| umask += 1 << i}  
		umask << range
  end
  
  def umask_bin
	  umask = 0
		range = 32 - mask
		(0..range-1).each {|i| umask += 1 << i}  
		umask
	end
	
	def network_bin
    self.to_bin & mask_bin
  end
	
  def broadcast_bin
    mask_bin & network_bin | umask_bin;
  end
end