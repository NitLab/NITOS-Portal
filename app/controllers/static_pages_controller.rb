class StaticPagesController < ApplicationController

  include StaticPagesHelper

  def home
  end

  def about
  end

  def your_ssh_keys
  end

  def scheduler 
    columns = [ 
      "Name", "00:00", "00:30", "01:00", "01:30", "02:00", "02:30", "03:00",
      "03:30", "04:00", "04:30", "05:00", "05:30", "06:00", "06:30", "07:00",
      "07:30", "08:00", "08:30","09:00", "09:30", "10:00", "10:30", "11:00",
      "11:30", "12:00", "12:30", "13:00", "13:30", "14:00", "14:30", "15:00", 
      "15:30", "16:00", "16:30", "17:00", "17:30", "18:00", "18:30","19:00", 
      "19:30", "20:00", "20:30", "21:00", "21:30", "22:00", "22:30", "23:00", 
      "23:30"
    ]

    node_obj = Nodes.new
    @node_list = node_obj.get_node_list
    @node_list_names = node_obj.get_node_list_names
    @user_slices = getSlices()
    @leases = getLeases()
    @today_leases = getLeasesByDate("2014-09-15")

    num = @node_list_names.length

    rows = Array.new(num){Array.new(49,0)}

    $i=0

    while $i< num do
      rows[$i][0] = @node_list_names[$i]
      $i +=1
    end

    puts rows.inspect

    @reservation_table = rows.map{|r| Hash[ *columns.zip(r).flatten ] }
    puts @reservation_table.inspect  

    puts "aaaaaaaaaaaaaaaaaaaaaaaa"
    puts ""


    @reservation_table.each do |iterate|
      @today_leases.each do |t_lease|
        if iterate["Name"] == t_lease["components"][0]["component"]["name"]
          valid_from = t_lease["valid_from"].split('T')[1][0...-4]
          valid_until = t_lease["valid_until"].split('T')[1][0...-4]
          if valid_from < valid_until 
            iterate.each_key do |key|
              if key>= valid_from && key <= valid_until
                iterate[key] = 1
              end
            end
          else
            iterate.each_key do |key|
              if key >= valid_from  
                iterate[key] = 1
              end
            end
          end
          
        end
      end
      
    end
    puts @reservation_table

    @new_todo = {"hash" => 0}

  end

  def node_status
    node_obj = Nodes.new
    @node_list = node_obj.get_node_list    
  end

  def set_node_on
    node_id = params[:node_id]
    puts node_id
    setNodeON(node_id)
    respond_to do |format|
      format.json {render nothing: true}
    end
  end

  def set_node_off
    node_id = params[:node_id]
    puts node_id
    setNodeOFF(node_id)
    respond_to do |format|
      format.json {render nothing: true}
    end
  end

  def reset_node
    node_id = params[:node_id]
    resetNode(node_id)
    respond_to do |format|
      format.json {render nothing: true}
    end
  end

  def reserve_node
    node_id = params[:node_id]
    reserveNode(node_id)
    respond_to do |format|
      format.json {render nothing: true}
    end
  end

  
end
