#
# A barebones VCO REST API client
#
# Sample code:
# 
#   # Initialize, authenticate
#   client = VcoRequestManager.new('vcoX.velocloud.net')
#   client.authenticate('<USERNAME>', '<PASSWORD>')
#
#   # Make a call
#   data = client.call('enterprise/getEnterprise', {})
#   puts data
#
#
require 'uri'
require 'net/http'
require 'openssl'
require 'json'
require 'pstore'
require 'pp'

class VcoRequestManager

  def initialize(hostname, cert_verify = true)
    @hostname = hostname
    @https = Net::HTTP.new(@hostname, 443)
    @https.use_ssl = true
    if !cert_verify
      @https.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    @jar = PStore.new('cookies.pstore')
  end 

  def authenticate(username, password, is_operator = false)
    method = if is_operator then '/login/operatorLogin' else '/login/enterpriseLogin' end
    res = self._request(method, {:username => username, :password => password})
    case res
    when Net::HTTPSuccess
      hash = res.to_hash
      @jar.transaction do
        hash['set-cookie'].each { |value|
          @jar['velocloud.session'] = value
        }
      end
    else
      puts res.inspect
    end
  end

  def _request(method, params)

    uri = URI::HTTPS.build({:host => @hostname,
                            :path => '/portal/rest/' + method.gsub(/^\/+|\/+$/, '')})
    headers = {'Content-Type' => 'application/json'}
    @jar.transaction do
      unless @jar['velocloud.session'].nil?
        headers['Cookie'] = @jar['velocloud.session']
      end
    end
    req = Net::HTTP::Post.new(uri, headers)
    req.body = params.to_json
    @https.request(req)

  end

  def call(method, params)

    res = self._request(method, params)

    case res
    when Net::HTTPSuccess
      JSON.parse(res.body)
    else
      puts res.inspect
      nil
    end

  end

end # END VcoRequestManager
