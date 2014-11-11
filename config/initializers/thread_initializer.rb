include NodeStatusHelper

class Nodes

  x= []
  # @@node_list: a table with the numbers of nodes. ex: for node 
  # node121 we add 121. Used in node status for turning ON/OFF/reset a node
  Nodes.class_variable_set(:@@node_list, x)

  z= []
  # @@resources_list_names: table with the names of resources. ex for node node121 we add node121,for channel 1 we add 1
  Nodes.class_variable_set(:@@resources_list_names, z)

  # @@resources_list_uuids:hash with the uuids of the resources 
  @@resources_list_uuids = Hash.new
  # @@hash_details_of_resources: hash with all informations of a resource, used for showing the details of every resource in scheduler  
  @@hash_details_of_resources = Hash.new


  def refresh_resources_list
    x= []
    Nodes.class_variable_set(:@@node_list, x)

    z= []
    Nodes.class_variable_set(:@@resources_list_names, z)

    node_list = getNodeList()
    channels_list = getChannelsList()

    node_list.each do |element|

      if (!element["hardware_type"].nil?) && ( element["hardware_type"].start_with? ("PC-"))
        @@node_list << element["name"].scan( /\d+$/ ).first
        @@resources_list_uuids[element["name"]] = element["uuid"]
        @@hash_details_of_resources[element["name"]] = element

        @@resources_list_names << element["name"]
      end
    end

    channels_list.each do |element|
      @@resources_list_names << element["name"]
      @@resources_list_uuids[element["name"]] = element["uuid"]
      @@hash_details_of_resources[element["name"]] = element
    end

  end

  def get_resources_list_names
    return @@resources_list_names
  end

  def get_resources_list_uuids
    return @@resources_list_uuids
  end

  def get_node_list
    return @@node_list 
  end

  def get_details_of_resources
    return @@hash_details_of_resources
  end

end

node_obj = Nodes.new

# thread for updating the lists referring to resources
Thread.new do
  while true do
    node_obj.refresh_resources_list
    sleep APP_CONFIG['broker_sleep']
  end
end

# thread for updating the status of every node. We ask with getNodeStatus the status of every node
# and then we inform with the websocket the front-end
Thread.new do
  while true do
    node_obj.get_node_list.each do |n|
      res = getNodeStatus(n)    
      temp = JSON.parse(res.body)

      WebsocketRails[:nodes].trigger 'status', temp
    end

    sleep APP_CONFIG['cm_sleep']
  end
end