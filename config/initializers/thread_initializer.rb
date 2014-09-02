include StaticPagesHelper

class Nodes

  x= []
  Nodes.class_variable_set(:@@node_list, x)

  y= []
  Nodes.class_variable_set(:@@node_list_names, y)

  @@node_list_uuids = Hash.new

  def refresh_node_list
    x= []
    Nodes.class_variable_set(:@@node_list, x)

    y= []
    Nodes.class_variable_set(:@@node_list_names, y)
    node_list = getNodeList()
    node_list.each do |element|
      if (element["hardware_type"].start_with? ("PC-"))
        @@node_list << element["name"].scan( /\d+$/ ).first
        @@node_list_names << element["name"]
        @@node_list_uuids[element["name"]] = element["uuid"]
      end
    end
  end

  def get_node_list_uuids
    return @@node_list_uuids 
  end

  def get_node_list_names
    return @@node_list_names 
  end

  def get_node_list
    return @@node_list 
  end

end

node_obj = Nodes.new

Thread.new do
  while true do
    node_obj.refresh_node_list
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