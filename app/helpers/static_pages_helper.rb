module StaticPagesHelper

	require "httparty"
  	require "json"

  	def getNodeStatus(node_id)
	    $node_num = node_id
	    
	    res = HTTParty.get("http://83.212.32.165:4567/resources/node/#$node_num")
	    puts JSON.parse(res.body)

	    return res

	  end

	def setNodeON(node_id)
		$node_num = node_id

		options = {body: {state:"on"}.to_json, :headers => { 'Content-Type' => 'application/json' }}
	  	res = HTTParty.put("http://83.212.32.165:4567/resources/node/#$node_num", options)
	  	puts JSON.parse(res.body)
	  	
	end

	def setNodeOFF(node_id)
		
		$node_num = node_id
		options = {body: {state:"off"}.to_json, :headers => { 'Content-Type' => 'application/json' }}
	  	res = HTTParty.put("http://83.212.32.165:4567/resources/node/#$node_num", options)
	  	puts JSON.parse(res.body)
	  	
	end

end
