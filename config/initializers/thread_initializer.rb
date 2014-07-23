include StaticPagesHelper

Thread.new do
      while true do
        #puts "I m in a thread !. Thread............1 "
        #puts "res"

        node_list = getNodeList()
        node_list.each do |element|
            res = getNodeStatus(element["name"])    
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
      end
    end