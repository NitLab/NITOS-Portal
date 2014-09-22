module SchedulerHelper

  require "httparty"
  require "json"
  require "net/https"
  require "uri"

  def httpGETRequest(http)

    uri = URI.parse(http)
    pem = File.read("/home/zamihos/user_cert.pem")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.cert = OpenSSL::X509::Certificate.new(pem)
    http.key = OpenSSL::PKey::RSA.new(pem)
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)

    return response = http.request(request) 
  end

  def getAccounts
    #http = "https://83.212.32.165:8001/resources/accounts"
    broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s
    http = broker_url + "/resources/accounts"
    res = httpGETRequest(http)
    return res
  end

  def getLeases
    broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s
    result = HTTParty.get(broker_url + "/resources/leases", :verify => false)
    temp = JSON.parse(result.body)

    leases =  temp["resource_response"]["resources"]

  end

  def getLeasesByDate(date)
    leases = getLeases()
    today_leases = []
    leases.each do |lease|
      if lease["status"] == "accepted"
        #puts "Gia na assssssssssssss"
        #puts lease["valid_from"].split('T')[0]
        #puts date
        #puts lease["valid_until"].split('T')[0]
        if  lease["valid_from"].split('T')[0] <= date && lease["valid_until"].split('T')[0]>=date
          #puts "mpika"
          today_leases << lease
        end
      end
    end

    return today_leases
  end

  def getSlices
    broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s
    result = HTTParty.get(broker_url + "/resources/users?name=ardadouk", :verify => false)

    temp = JSON.parse(result.body)

    user_slices = []
    user_data =  temp["resource_response"]["resources"]
    user_data.each do |element|
      element["projects"].each do |slice|
        user_slices << slice["account"]["name"]
      end
    end
    return user_slices
  end

  def reserveNode(node_id,account_name,valid_from,valid_until)
    resernation_name =account_name+ "/" + (1000 + Random.rand(10000000)).to_s
    puts "namaasdfasd fasdfasdfaskjhdfkjasdhf asdfjh"
    puts resernation_name
    puts node_id
    broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s
    header = {"Content-Type" => "application/json"}
    options ={
                  name: resernation_name,
                  valid_from: valid_from,
                  valid_until: valid_until,
                  account: 
                    { 
                      name: account_name
                    },
                  components: 
                  [
                    { 
                      uuid: node_id
                    }
                  ]
                }

                

    uri = URI.parse(broker_url+"/resources/leases")
    pem = File.read("/home/zamihos/user_cert.pem")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.cert = OpenSSL::X509::Certificate.new(pem)
    http.key = OpenSSL::PKey::RSA.new(pem)
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = options.to_json

    response = http.request(request)
    puts response
    
  end
end
