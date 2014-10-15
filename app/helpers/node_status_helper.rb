module NodeStatusHelper

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

  def hasRightForNode?(node_id)
    puts "hasRightForNode"
    hash = Hash.new
    hash = getLeasesByAccount
    #puts hash.inspect
    node_id = "node"+node_id
    #puts node_id
    date_now = Time.now.to_s.split(" ")[0]
    time_now = Time.now.to_s.split(" ")[1][0...-3]
    time = date_now+"T"+time_now
    #puts time


    hash.each_value do |value|
      value.each do |reservation|
        #if reservation != nil
          reservation["components"].each do |element|
            if element["component"]["name"] == node_id && reservation["valid_from"].to_s[0...-4]<= time && reservation["valid_until"].to_s[0...-4] > time
              return true
            end
          end
        #end
      end
    end

    return false

  end
end
