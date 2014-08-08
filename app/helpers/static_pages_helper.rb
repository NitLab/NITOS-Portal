module StaticPagesHelper

	require "httparty"
  require "json"

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

end
