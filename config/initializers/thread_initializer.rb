include StaticPagesHelper

class Nodes

  x= []
  Nodes.class_variable_set(:@@node_list, x)

  def refresh_node_list
    x= []
    Nodes.class_variable_set(:@@node_list, x)
    node_list = getNodeList()
    node_list.each do |element|
      if (element["hardware_type"].start_with? ("PC-"))
        @@node_list << element["name"]
      end
    end
  end

  def get_node_list
    puts @@node_list
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

    res = getNodeStatus("120")
    temp = JSON.parse(res.body)
    WebsocketRails[:nodes].trigger 'status', temp 

    num = 'status121'
    res = getNodeStatus("121")
    temp = JSON.parse(res.body)
    WebsocketRails[:nodes].trigger 'status', temp 

    sleep APP_CONFIG['cm_sleep']
  end
end