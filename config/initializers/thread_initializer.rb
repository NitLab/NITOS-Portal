include NodeStatusHelper

class Nodes

  x= []
  Nodes.class_variable_set(:@@node_list, x)

  z= []
  Nodes.class_variable_set(:@@resources_list_names, z)

  @@resources_list_uuids = Hash.new
  @@hash_details_of_resources = Hash.new

  @@resources_list = Hash.new
  def refresh_resources_list
    x= []
    Nodes.class_variable_set(:@@node_list, x)

    z= []
    Nodes.class_variable_set(:@@resources_list_names, z)

    node_list = getNodeList()
    channels_list = getChannelsList()

    node_list.each do |element|
      if (element["hardware_type"].start_with? ("PC-"))
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

Thread.new do
  while true do
    node_obj.refresh_resources_list
    sleep APP_CONFIG['broker_sleep']
  end
end

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