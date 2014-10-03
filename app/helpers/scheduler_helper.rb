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
    leases = []
    puts "Test"
    puts temp
    if ! temp.has_key?("exception")
      leases =  temp["resource_response"]["resources"]
    end
    return leases
  end

  def getLeasesByDate(date)
    leases = getLeases()
    today_leases = []
    if leases.length !=0
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
    end

    return today_leases
  end

  def getLeasesBySlice(slice)
    leases = getLeases()
    this_slice_leases = []
    leases.each do |lease|
      if lease["status"] == "accepted"
        if lease["account"]["name"] == slice
          if lease["valid_until"].split('T')[0] > Date.today.to_s 
            this_slice_leases << lease
          elsif lease["valid_until"].split('T')[0] == Date.today.to_s 
            if lease["valid_until"].split('T')[1][0...-4] > Time.now.to_s.split(' ')[1][0...-3]
              this_slice_leases << lease
            end   
          end
        end
      end
    end
    return this_slice_leases
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

  def reserveNode(node_ids,account_name,valid_from,valid_until)
    resernation_name =account_name+ "/" + (1000 + Random.rand(10000000)).to_s
    puts "namaasdfasd fasdfasdfaskjhdfkjasdhf asdfjh"
    puts resernation_name
    
    broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s

    node_ids.map!{|r| {uuid: r}}

    header = {"Content-Type" => "application/json"}
    options ={
                  name: resernation_name,
                  valid_from: valid_from,
                  valid_until: valid_until,
                  account: 
                    { 
                      name: account_name
                    },
                  components: node_ids
                }

    #puts options.to_json            
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
    if response.header.code != '200'
      puts "Something went wrong"
      puts response
    end
    
  end

  def unboundRequest(params)
    broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s

    # dokimh1
    resources = []

    h1 = Hash.new
    h2 = Hash.new

    time_now =  Time.now.to_s.split(" ")[1][0...-3]
    time_from = roundTimeUp(time_now)
    valid_from = Time.now.to_s.split(" ")[0] + " " +time_from+ ":00 +0000"

    puts "Gia na doume tous xronous"
    puts Time.now
    puts valid_from

    if params[:duration_t1] != ""
      h1 = { type: params[:type1], exclusive: true, duration: params[:duration_t1].to_i, valid_from: valid_from}
    else
      h1 = { type: params[:type1], exclusive: true, valid_from: valid_from}
    end

    params[:number_t1].to_i.times {resources << h1}

    if params[:type2] != "" && params[:number_t2] != ""
      if params[:duration_t2] != ""
        h2 = { type: params[:type2], exclusive: true, duration: params[:duration_t2].to_i, valid_from: valid_from }
      else
        h2 = { type: params[:type2], exclusive: true, valid_from: valid_from }
      end
      params[:number_t2].to_i.times {resources << h2}
    end

    # Harcoded request
    # t1 = Time.now + 21600
    # puts t1
    options = {body: {
      resources: resources
    }.to_json, :headers => { 'Content-Type' => 'application/json' } , :verify => false}
    response = HTTParty.get(broker_url+"/resources", options)

    puts options

    if response.header.code != '200'
      puts "Something went wrong"
      puts response
    else    
      puts response
      return response
    end
  end

  def roundTimeUp(time)
    if time.split(':')[1] >= "30"
      if time.split(':')[0] != "23"
        time = time.split(':')[0].to_i + 1
        time = time.to_s + ":00"
      else
        time = "23:59"
      end
    else
      time = time.split(':')[0] + ":30"
    end
    return time
  end 

  def roundTimeFrom(time)
    if time.split(':')[1] >= "30"
      time = time.split(':')[0] + ":30"
    else
      time = time.split(':')[0] + ":00"
    end
  end

  def roundTimeUntil(time)
    if time.split(':')[1] != "00" && time.split(':')[1] != "30"
      if time.split(':')[1] >= "30"
        if time.split(':')[0] != "23"
          time = time.split(':')[0].to_i + 1
          time = time.to_s + ":00"
        else
          time = "23:59"
        end
      else
        time = time.split(':')[0] + ":30"
      end
    end
    return time
  end

  def cancelReservation(lease_uuid)
    broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s

    header = {"Content-Type" => "application/json"}
    options = {uuid: lease_uuid}

    #puts options.to_json            
    uri = URI.parse(broker_url+"/resources/leases")
    pem = File.read("/home/zamihos/user_cert.pem")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.cert = OpenSSL::X509::Certificate.new(pem)
    http.key = OpenSSL::PKey::RSA.new(pem)
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Delete.new(uri.request_uri, header)
    request.body = options.to_json

    response = http.request(request)
    puts response
    if response.header.code != '200'
      puts "Something went wrong"
      puts response
    end
  end

end
