class StaticPagesController < ApplicationController

  include StaticPagesHelper

  def home
  end

  def about
  end

  def your_ssh_keys
  end

  def scheduler 
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

  
  def reservation

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
    @date = (Date.civil(params[:start_date][:year].to_i,params[:start_date][:month].to_i, params[:start_date][:day].to_i)).to_s
    # puts "H hmeromhnia einai " 
    # puts @date 
    @node_list = node_obj.get_node_list
    @node_list_names = node_obj.get_node_list_names
    #puts @node_list_uuids
    @user_slices = getSlices()
    #@leases = getLeases()
    @today_leases = getLeasesByDate(@date)

    num = @node_list_names.length

    rows = Array.new(num){Array.new(49,0)}

    $i=0

    while $i< num do
      rows[$i][0] = @node_list_names[$i]
      $i +=1
    end

    #puts rows.inspect

    @reservation_table = rows.map{|r| Hash[ *columns.zip(r).flatten ] }
    #puts @reservation_table.inspect  
    # puts @today_leases.inspect
    puts @today_leases.inspect

    @reservation_table.each do |iterate|
      @today_leases.each do |t_lease|
        date_from = t_lease["valid_from"].split('T')[0]
        date_until = t_lease["valid_until"].split('T')[0]
        time_form = t_lease["valid_from"].split('T')[1][0...-4]
        time_until = t_lease["valid_until"].split('T')[1][0...-4]
        puts date_from
        puts date_until
        puts time_form
        puts time_until
        puts @date


        if iterate["Name"] == t_lease["components"][0]["component"]["name"]
          if date_from == date_until
            iterate.each_key do |key|
              if key >= time_form && key < time_until && key != "Name" 
                iterate[key] = 1
              end
            end
          elsif date_from < date_until
            if @date == date_from
              iterate.each_key do |key|
                if key >= time_form && key != "Name" 
                  iterate[key] = 1
                end
              end
            elsif @date == date_until
              iterate.each_key do |key|
                if key < time_until  
                  iterate[key] = 1
                end
              end
            else
              iterate.each_key do |key|
                if key != "Name"  
                  iterate[key] = 1
                end
              end
            end             
          end
          
        end
      end
      
    end
    puts @reservation_table
        
  end

  def make_reservation
    #Apo dw kai katw einai to palio resevation 
    
    node_obj = Nodes.new
    @node_list_uuids = node_obj.get_node_list_uuids
    # Vriskw poioi komvoi einai pros krathsh 
    ids = []
    reservations = params[:reservations]
    #puts params[:user_slice]

    #@date =  (Date.civil(params[:start_date][:year].to_i,params[:start_date][:month].to_i, params[:start_date][:day].to_i)).to_s
    @date = ""
    @date = reservations[0].split('/')[1][0...-6]
    
    #puts reservations
    reservations.each do |reservation|
      if !ids.include?(reservation.split('/')[0])
        ids << reservation.split('/')[0]
      end
    end

    #Dhmiourgw hash gia kathe komvo 
    ids.each_index do |i|
      r_name = ids[i]
      ids[i] = {"Name"=>r_name, @date+" 00:00"=>0, @date+" 00:30"=>0, @date+" 01:00"=>0, @date+" 01:30"=>0,
     @date+" 02:00"=>0, @date+" 02:30"=>0, @date+" 03:00"=>0, @date+" 03:30"=>0, @date+" 04:00"=>0, @date+" 04:30"=>0,
      @date+" 05:00"=>0, @date+" 05:30"=>0, @date+" 06:00"=>0, @date+" 06:30"=>0, @date+" 07:00"=>0, @date+" 07:30"=>0,
       @date+" 08:00"=>0, @date+" 08:30"=>0, @date+" 09:00"=>0, @date+" 09:30"=>0, @date+" 10:00"=>0, @date+" 10:30"=>0,
        @date+" 11:00"=>0, @date+" 11:30"=>0, @date+" 12:00"=>0, @date+" 12:30"=>0, @date+" 13:00"=>0, @date+" 13:30"=>0,
         @date+" 14:00"=>0, @date+" 14:30"=>0, @date+" 15:00"=>0, @date+" 15:30"=>0, @date+" 16:00"=>0, @date+" 16:30"=>0,
          @date+" 17:00"=>0, @date+" 17:30"=>0, @date+" 18:00"=>0, @date+" 18:30"=>0, @date+" 19:00"=>0, @date+" 19:30"=>0,
           @date+" 20:00"=>0, @date+" 20:30"=>0, @date+" 21:00"=>0, @date+" 21:30"=>0, @date+" 22:00"=>0, @date+" 22:30"=>0,
            @date+" 23:00"=>0, @date+" 23:30"=>0, @date+" 23:59"=>0}
      
    end

    #Sumplhrwnw o kathe hash me tis krathseis 
    ids.each do |element|
      reservations.each do |reservation|
        if reservation.split('/')[0] == element["Name"]
          element[reservation.split('/')[1]] =1
        end
      end
    end
    #puts ids

    
    #Vriskw valid_fom kai valid_until gia kathe aithsh 
    num = 0
    valid_from = ""
    valid_until = ""
    ids.each do |element|
      element.each do |key,value|
        #puts key
        #puts value
        if num ==0
          if value ==1
            #puts "mpika "
            valid_from = key
            #puts valid_from
            num += 1
          end
        else 
          if value ==0
            valid_until = key
            #stelnw krathsh 
            #element["Name"]
            valid_from = valid_from + ":00 +0000"
            valid_until = valid_until + ":00 +0000"
            reserveNode(@node_list_uuids[element["Name"]],params[:user_slice],valid_from,valid_until)

            # puts "Tha kanw krathsh me valid_from"
            # puts valid_from
            # puts "kai valid_until"
            # puts valid_until
            # puts "Gia ton "+element["Name"] + "me uuid=" + @node_list_uuids[element["Name"]]
            num = 0
          end
        end
      end
    end

  redirect_to :back
  end 

end
