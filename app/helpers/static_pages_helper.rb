module StaticPagesHelper

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
			if  lease["valid_from"].include?(date) || lease["valid_until"].include?(date)
				today_leases << lease
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

  def getNodeList
  	broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s
		result = HTTParty.get(broker_url + "/resources/nodes", :verify => false)
		temp2 = JSON.parse(result.body)

		node_data =  temp2["resource_response"]["resources"]
		return node_data
  		
  end

  def getNodeStatus(node_id) 			   
	   cm_url = APP_CONFIG['cm_ip'] + ':' + APP_CONFIG['cm_port'].to_s
	   res = HTTParty.get(cm_url+"/resources/node/"+ node_id)

	   return res

	end

	def setNodeON(node_id)
		cm_url = APP_CONFIG['cm_ip'] + ':' + APP_CONFIG['cm_port'].to_s

		options = {body: {state:"on"}.to_json, :headers => { 'Content-Type' => 'application/json' }}
	  	res = HTTParty.put(cm_url+"/resources/node/"+ node_id, options)
	  	
	end

	def setNodeOFF(node_id)		
		cm_url = APP_CONFIG['cm_ip'] + ':' + APP_CONFIG['cm_port'].to_s

		options = {body: {state:"off"}.to_json, :headers => { 'Content-Type' => 'application/json' }}
	  	res = HTTParty.put(cm_url+"/resources/node/"+ node_id, options)
	  	
	end

	def resetNode(node_id)		
		cm_url = APP_CONFIG['cm_ip'] + ':' + APP_CONFIG['cm_port'].to_s

		options = {body: {state:"reset"}.to_json, :headers => { 'Content-Type' => 'application/json' }}
	  	res = HTTParty.put(cm_url+"/resources/node/"+ node_id, options)
	  	
	end

	def reserveNode(node_id)
		broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s
		header = {"Content-Type" => "application/json"}
		options ={
							 		name: '|111111',
							 		valid_from: '2014-09-15 15:00:00 +0300',
							 		valid_until: '2014-09-15 17:00:00 +0300',
							 		account: 
							 			{ 
							 				name: 'ardadouk'
							 			},
							 		components: 
							 		[
							 			{ 
							 				uuid: 'fa3d3969-7705-453c-850c-8a1e78f33221'
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
