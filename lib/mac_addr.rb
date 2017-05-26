# Utilities for working with Mac Addresses.
# Handy for use with V1-style screen URLs where macs are common.
module MacAddr

  # Condense a mac address to a small string.
  # Strip out any puncuation and leading 0s.
  # If the mac is all 0s then we return a single 0.
  #
  # @param mac_addr [String] Mac address.
  # @return [String] The condensed mac address
  def self.condense(mac_addr)
    mac_addr = mac_addr.downcase.gsub(/[^a-z\d]/,'')

    # If the mac address is all 0s then we condense it down to 1 zero
    return "0" if /^0+$/.match(mac_addr)

    mac_addr = mac_addr.gsub(/^0+/,'')
    return mac_addr
  end

  # Expand a mac address to a full string.
  # Pad with 0s and add some colon delimiters.
  #
  # @param mac_addr [String] Condensed mac address.
  # @return [String] 12 character mac address with colons.
  def self.expand(mac_addr)
    mac_addr = mac_addr.rjust(12, '0')
    octects = mac_addr.scan(/../)
    return octects.join(':')
  end

  # Convert int mac address to hex.
  #
  # @param int_addr [Integer] Numeric representation of a mac address.
  # @return [String] Expanded mac address.
  def self.to_hex(int_addr)
    hex = int_addr.to_s(16)
    return expand(hex)
  end

  # Convert mac address to an integer.
  #
  # @param hex_addr [String] Expanded Mac address.
  # @return [Integer] Integer mac address.
  def self.to_i(hex_addr)
    hex = condense(hex_addr)
    return hex.to_i(16)
  end

end
