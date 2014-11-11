module NodeStatusHelper

  require "httparty"
  require "json"

  # getNodeList: returns the list of nodes
  def getNodeList
    broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s
    result = HTTParty.get(broker_url + "/resources/nodes", :verify => false)
    temp2 = JSON.parse(result.body)

    node_data =  temp2["resource_response"]["resources"]
    return node_data
      
  end

  # getChannelsList: returns the list of channels
  def getChannelsList
    broker_url = APP_CONFIG['broker_ip'] + ':' + APP_CONFIG['broker_port'].to_s
    result = HTTParty.get(broker_url + "/resources/channels", :verify => false)
    temp2 = JSON.parse(result.body)

    channels_data =  temp2["resource_response"]["resources"]
    return channels_data
      
  end

  # getNodeStatus: returns the status of node_id
  def getNodeStatus(node_id)         
     cm_url = APP_CONFIG['cm_ip'] + ':' + APP_CONFIG['cm_port'].to_s
     res = HTTParty.get(cm_url+"/resources/node/"+ node_id)
     # puts "status "+node_id
     # puts res
     return res

  end

  # setNodeON: sets node_id node ON
  def setNodeON(node_id)
    cm_url = APP_CONFIG['cm_ip'] + ':' + APP_CONFIG['cm_port'].to_s

    options = {body: {state:"on"}.to_json, :headers => { 'Content-Type' => 'application/json' }}
      res = HTTParty.put(cm_url+"/resources/node/"+ node_id, options)
      
  end

  # setNodeOFF: sets node_id node OFF
  def setNodeOFF(node_id)   
    cm_url = APP_CONFIG['cm_ip'] + ':' + APP_CONFIG['cm_port'].to_s

    options = {body: {state:"off"}.to_json, :headers => { 'Content-Type' => 'application/json' }}
      res = HTTParty.put(cm_url+"/resources/node/"+ node_id, options)
      
  end

  # resetNode: resets node_id
  def resetNode(node_id)    
    cm_url = APP_CONFIG['cm_ip'] + ':' + APP_CONFIG['cm_port'].to_s

    options = {body: {state:"reset"}.to_json, :headers => { 'Content-Type' => 'application/json' }}
      res = HTTParty.put(cm_url+"/resources/node/"+ node_id, options)
      
  end

  # hasRightForNode: check if a users has the right to turn a node ON/OFF or reset a node, according to the current-active user's accound leases
  def hasRightForNode?(node_id)
    puts "hasRightForNode"
    hash = Hash.new
    hash = getLeasesByAccount
    #puts hash.inspect
    node_id = "node"+node_id
    #puts node_id
    # date_now = Time.zone.now.to_s.split(" ")[0]
    # time_now = Time.zone.now.to_s.split(" ")[1][0...-3]
    # time = date_now+"T"+time_now
    #puts time
    time = Time.zone.now.to_s

    hash.each_value do |value|
      value.each do |reservation|
        #if reservation != nil
          reservation["components"].each do |element|
            if element["component"]["name"] == node_id && reservation["valid_from"].to_s<= time && reservation["valid_until"].to_s > time
              return true
            end
          end
        #end
      end
    end

    return false

  end
end
