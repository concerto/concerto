module DashboardHelper  
def latest_version
  require 'net/https'
  require 'uri'
  require 'json'
  
  uri = URI.parse('https://api.github.com/repos/concerto/concerto/git/refs/tags')
  http = Net::HTTP.new(uri.host, uri.port)
  if uri.scheme == "https" # enable SSL/TLS
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_PEER
    http.ca_file = Rails.root.join('config', 'cacert.pem').to_s
  end
  http.start {
    http.request_get(uri.path) {|res|
      @versions = Array.new
      JSON.parse(res.body).each do |tag|
        @versions << tag['ref'].gsub(/refs\/tags\//,'')
      end
      @versions.sort! {|x,y| y <=> x }
      return @versions[0]
    }
  }
end
end