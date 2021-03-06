module SchedulerHelper

  require "httparty"
  require "json"
  require "net/https"
  require "uri"

  def httpGETRequest(http)
    cert_path = APP_CONFIG['cert_path']
    uri = URI.parse(http)
    pem = File.read(cert_path)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.cert = OpenSSL::X509::Certificate.new(pem)
    http.key = OpenSSL::PKey::RSA.new(pem)
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Get.new(uri.request_uri)

    return response = http.request(request) 
  end

  # getAccounts: returns the accounts exist in broker
  def getAccounts
    broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s
    http = broker_url + "/resources/accounts"
    res = httpGETRequest(http)
    return res
  end

  # getLeases: returns all the leases according user's timezone
  def getLeases
    broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s
    result = HTTParty.get(broker_url + "/resources/leases", :verify => false)
    temp = JSON.parse(result.body)
    leases = []
    puts "Test"
    puts temp
    if ! temp.has_key?("exception")
      temp["resource_response"]["resources"].each do |lease|
        #puts "Allagh wras sta leases sumfwna me to timezone tou xrhshth"
        #puts lease["valid_from"]
        lease["valid_from"] = Time.strptime(lease["valid_from"], '%Y-%m-%dT%H:%M:%S%z').in_time_zone(Time.zone).to_s
        #puts lease["valid_from"]
        #puts lease["valid_until"]
        lease["valid_until"] = Time.strptime(lease["valid_until"], '%Y-%m-%dT%H:%M:%S%z').in_time_zone(Time.zone).to_s
        #puts lease["valid_until"]

        leases << lease

      end
    end
    return leases
  end

  # getLeasesByDate: returns the leases for a given date 
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
          if  lease["valid_from"].split(' ')[0] <= date && lease["valid_until"].split(' ')[0]>=date
            #puts "mpika"
            today_leases << lease
          end
        end
      end
    end

    return today_leases
  end

  # getLeasesBySlice: returns the leases for a given slice,from this moment and on 
  def getLeasesBySlice(slice)
    leases = getLeases()
    this_slice_leases = []
    leases.each do |lease|
      if lease["status"] == "accepted"
        if lease["account"]["name"] == slice
          if lease["valid_until"].split(' ')[0] > Time.zone.today.to_s 
            this_slice_leases << lease
          elsif lease["valid_until"].split(' ')[0] == Time.zone.today.to_s 
            if lease["valid_until"].split(' ')[1][0...-3] > Time.zone.now.to_s.split(' ')[1][0...-3]
              this_slice_leases << lease
            end   
          end
        end
      end
    end
    return this_slice_leases
  end

  # getLeasesByAccount: returns the leases for a given account 
  def getLeasesByAccount
    #puts "Eimai mesa sthn getLeasesByAccount"
    this_account_slices = []
    this_account_slices = getSlices
    #puts this_account_slices.inspect
    this_account_reservations = Hash.new
    if this_account_slices.length != 0    
      this_account_slices.each do |slice|
        this_slice_leases = []
        this_slice_leases = getLeasesBySlice(slice)        

        #Sort my slices by valid_from
        this_slice_leases = this_slice_leases.sort_by{|hsh| hsh["valid_from"]}
        this_account_reservations[slice] = this_slice_leases       
        #puts "this_account_reservations "
        #puts this_account_reservations.inspect
      end
    end
    #puts "Edw teleiwnei h getLeasesByAccount"
    #puts this_account_reservations.inspect
    return this_account_reservations
  end

  # getSlices: returns the slices of the user(current_user) that is loged in
  def getSlices
    broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s
    result = HTTParty.get(broker_url + "/resources/users?name="+current_user.name, :verify => false)
    user_slices = []
    if result.header.code == '200'
      temp = JSON.parse(result.body)     
      user_data =  temp["resource_response"]["resources"]
      user_data.each do |element|
        element["projects"].each do |slice|
          user_slices << slice["account"]["name"]
        end
      end      
    else
      temp = JSON.parse(result.body)
      if temp["exception"]["reason"] == "No resources matching the request."
        flash[:danger] = "No resources matching the request. Please create a slice"
      else
        flash[:danger] = "Something went wrong !"
      end
    end

    return user_slices
  end

  # reserveNode: is responsible for constructing the request to reserve a resource 
  # parameters: 1) node_ids: a table with the uuids of the resources that we want to reserve
  #             2) account_name: the given slice we use for reservation
  #             3) valid_from: the start time for reservation
  #             4) valid_until: the end time of reservation
  def reserveNode(node_ids,account_name,valid_from,valid_until)
    cert_path = APP_CONFIG['cert_path']
    # resernation_name: we set a random name for every reservation constructing by the name of the slice and a random number ex user1/12341234 
    resernation_name =account_name+ "/" + (1000 + Random.rand(10000000)).to_s
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
    pem = File.read(cert_path)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.cert = OpenSSL::X509::Certificate.new(pem)
    http.key = OpenSSL::PKey::RSA.new(pem)
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    request = Net::HTTP::Post.new(uri.request_uri, header)
    request.body = options.to_json

    response = http.request(request)
    
    res = JSON.parse(response.body)
    
    if response.header.code != '200'
      puts "Something went wrong"
      puts response 
      puts res["exception"]["reason"]
      return res["exception"]["reason"]
    else
      return "OK"
    end
    
  end

  # unboundRequest: respnsoble for constructing the request for making an unbound request 
  def unboundRequest(params)
    broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s

    resources = []

    h1 = Hash.new
    h2 = Hash.new

    # puts Time.zone.now

    if params[:start_date] != ""
      valid_from = params[:start_date] + ":00 "
      valid_from = Time.zone.parse(valid_from)
    else
      time_now =  Time.zone.now.to_s.split(" ")[1][0...-3]
      time_from = roundTimeUp(time_now)
      valid_from = Time.zone.now.to_s.split(" ")[0] + " " +time_from+ ":00 "
      valid_from = Time.zone.parse(valid_from)
    end

    #For nodes
    if params[:number_of_nodes] != ""
      if params[:duration_t1] != ""
        if params[:domain1] != ""
          h1 = { type: "Node", exclusive: true, duration: params[:duration_t1].to_i, valid_from: valid_from, domain: params[:domain1]}
        else
          h1 = { type: "Node", exclusive: true, duration: params[:duration_t1].to_i, valid_from: valid_from}
        end
      else
        if params[:domain1] != ""
          h1 = { type: "Node", exclusive: true, valid_from: valid_from, domain: params[:domain1]}
        else
          h1 = { type: "Node", exclusive: true, valid_from: valid_from}
        end
      end      

      params[:number_of_nodes].to_i.times {resources << h1}

    end

    #For channels
    if params[:number_of_channels] != ""
      if params[:duration_t1] != ""
        if params[:domain1] != ""
          h1 = { type: "Channel", exclusive: true, duration: params[:duration_t1].to_i, valid_from: valid_from, domain: params[:domain1]}
        else
          h1 = { type: "Channel", exclusive: true, duration: params[:duration_t1].to_i, valid_from: valid_from}
        end
      else
        if params[:domain1] != ""
          h1 = { type: "Channel", exclusive: true, valid_from: valid_from, domain: params[:domain1]}
        else
          h1 = { type: "Channel", exclusive: true, valid_from: valid_from}
        end
      end      

      params[:number_of_channels].to_i.times {resources << h1}

    end

    options = {body: {
      resources: resources
    }.to_json, :headers => { 'Content-Type' => 'application/json' } , :verify => false}
    response = HTTParty.get(broker_url+"/resources", options)

    puts options

    if response.header.code != '200'
      puts "Something went wrong"
      puts response
      flash[:danger] = response
    else    
      puts response
      response["resource_response"]["resources"].each do |element|
        element["valid_from"] = Time.zone.parse(element["valid_from"]).to_s
        element["valid_until"] = Time.zone.parse(element["valid_until"]).to_s
      end

      return response
    end
  end

  # roundTimeUp: used in unboundRequest for converting the time to the next half hour 
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

  # roundTimeFrom: used for rounding time 
  # used in scheduler for showing reservation with start time between :00-:30
  # ex if valid_from = 13:15 we convert it to 13:00
  def roundTimeFrom(time)
    if time.split(':')[1] >= "30"
      time = time.split(':')[0] + ":30"
    else
      time = time.split(':')[0] + ":00"
    end
  end

  # roundTimeUntil: used for rounding time 
  # used in scheduler for showing reservation with end time between :00-:30
  # ex if valid_until = 13:15 we convert it to 13:30
  # ex if valid_until = 13:45 we convert it to 14:00
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

  # cancelReservation: responsible for canceling a reservation. cancels the reservation with the passed uuid 
  def cancelReservation(lease_uuid)
    broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s    
    cert_path = APP_CONFIG['cert_path']
    
    header = {"Content-Type" => "application/json"}
    options = {uuid: lease_uuid}

    #puts options.to_json            
    uri = URI.parse(broker_url+"/resources/leases")
    pem = File.read(cert_path)
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

  # set_timezone: we set the user's timezone according to the timezone passed throw the cookie
  # if something goes wrong we set timezone to the default timezone
  def set_timezone
    default_timezone = Time.zone
    client_timezone  = cookies[:timezone]
    # puts "Na to to coooookie"
    # puts client_timezone
    Time.zone = client_timezone if client_timezone.present?
    yield
  ensure
    Time.zone = default_timezone
  end

end
