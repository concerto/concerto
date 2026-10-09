require "resolv"
require "ipaddr"

# Guards server-initiated HTTP fetches (a feed's own configured URL, or a URL
# supplied by that feed's response, e.g. a "Graphic" item's image URL)
# against being pointed at the server's own internal network.
#
# Without this, any actor who can set or influence a fetched URL -- a feed
# manager editing a RemoteFeed/RssFeed's `url`, or an otherwise-trusted
# external feed whose *response* supplies a secondary URL -- can make this
# server issue HTTP requests to loopback addresses, RFC1918/link-local
# ranges, or cloud metadata endpoints (SSRF, CWE-918).
#
# Deliberately a blocklist of reserved/internal ranges rather than an
# allowlist of "public" ranges: "public" has no closed-form definition, but
# the reserved ranges are a fixed, enumerable set (IANA special-purpose
# registries). Resolves the hostname and checks every returned address, so a
# hostname that resolves to a private address (DNS rebinding, `localtest.me`-
# style domains, etc.) is rejected even though the hostname string itself
# looks external.
module SafeExternalFetchable
  extend ActiveSupport::Concern

  RESERVED_RANGES = [
    IPAddr.new("0.0.0.0/8"),        # "this network"
    IPAddr.new("10.0.0.0/8"),       # RFC1918
    IPAddr.new("100.64.0.0/10"),    # shared address space (carrier NAT)
    IPAddr.new("127.0.0.0/8"),      # loopback
    IPAddr.new("169.254.0.0/16"),   # link-local (incl. cloud metadata)
    IPAddr.new("172.16.0.0/12"),    # RFC1918
    IPAddr.new("192.0.0.0/24"),     # IETF protocol assignments
    IPAddr.new("192.0.2.0/24"),     # documentation (TEST-NET-1)
    IPAddr.new("192.168.0.0/16"),   # RFC1918
    IPAddr.new("198.18.0.0/15"),    # benchmarking
    IPAddr.new("198.51.100.0/24"),  # documentation (TEST-NET-2)
    IPAddr.new("203.0.113.0/24"),   # documentation (TEST-NET-3)
    IPAddr.new("224.0.0.0/4"),      # multicast
    IPAddr.new("240.0.0.0/4"),      # reserved
    IPAddr.new("::1/128"),          # loopback
    IPAddr.new("::/128"),           # unspecified
    IPAddr.new("64:ff9b::/96"),     # NAT64 well-known prefix (may embed an IPv4 reserved address)
    IPAddr.new("100::/64"),         # discard-only
    IPAddr.new("fc00::/7"),         # unique local
    IPAddr.new("fe80::/10"),        # link-local
    IPAddr.new("::ffff:0:0/96")     # IPv4-mapped IPv6 -- unwrapped below, kept as a backstop
  ].freeze

  class_methods do
    # uri only needs to duck-type URI::Generic (#scheme, #host); accepts a
    # real URI so callers can parse once and reuse the result.
    def safe_external_uri?(uri)
      SafeExternalFetchable.safe?(uri)
    end
  end

  def self.safe?(uri)
    return false unless uri.respond_to?(:scheme) && uri.respond_to?(:host)
    return false unless %w[http https].include?(uri.scheme.to_s.downcase)

    host = uri.host
    return false if host.blank?

    addresses = Resolv.getaddresses(host)
    return false if addresses.empty?

    addresses.all? { |address| public_address?(address) }
  rescue Resolv::ResolvError, Resolv::ResolvTimeout, SocketError, IPAddr::Error
    false
  end

  SIXTOFOUR_RANGE = IPAddr.new("2002::/16").freeze

  def self.public_address?(address)
    ip = IPAddr.new(address)
    ip = ip.native if ip.ipv4_mapped? # unwrap ::ffff:a.b.c.d to its IPv4 form
    embedded = sixtofour_embedded_ipv4(ip)
    return public_address?(embedded) if embedded
    RESERVED_RANGES.none? { |range| ranges_overlap?(range, ip) }
  rescue IPAddr::Error
    false
  end

  # A 6to4 address (2002:WWXX:YYZZ::/16) encodes an IPv4 address in its
  # second and third hextets. Checking the 6to4 /16 itself as reserved would
  # also block 6to4 addresses that legitimately embed a public IPv4 address,
  # so the embedded address is extracted and checked on its own merits
  # instead of blocking the whole prefix.
  def self.sixtofour_embedded_ipv4(ip)
    return nil unless ip.ipv6? && SIXTOFOUR_RANGE.include?(ip)
    hextets = ip.hton.unpack("n8")
    octets = [hextets[1] >> 8, hextets[1] & 0xff, hextets[2] >> 8, hextets[2] & 0xff]
    octets.join(".")
  end
  private_class_method :sixtofour_embedded_ipv4

  def self.ranges_overlap?(range, ip)
    range.include?(ip)
  rescue IPAddr::Error
    # Family mismatch (one v4, one v6) means they can't overlap.
    false
  end
  private_class_method :ranges_overlap?, :public_address?
end
