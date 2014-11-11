class SchedulerController < ApplicationController
  include SchedulerHelper
  before_action :signed_in_user
  around_filter :set_timezone 
  #require "momentjs-rails"


  def unbound_requests
    
    node_obj = Nodes.new
    @node_list = node_obj.get_node_list
    @user_slices = getSlices()

    @mapping_result = []
    if params.has_key?("resource_response")
      @mapping_result = params["resource_response"]["resources"]
    end
    puts @mapping_result
    
  end

  # make_unbound_requests: called when find resources button clicked
  # responsible for making controls about required fields and invalid time.
  # responsible for calling unboundRequest with the relative parameters

  def make_unbound_requests
    # puts params

    mapping_result = []

    if params[:number_of_nodes] == "" && params[:number_of_channels] == ""
      flash[:danger] = "You should set number of nodes or channels to make an unbound request!"
    else
      if params[:start_date] !="" && params[:start_date] < Time.zone.now.to_s
        flash[:danger] = "Please select a timeslot in the future."
      else
        mapping_result = unboundRequest(params)
        puts "H sunarthsh mou epestrepse "
        puts mapping_result
      end   
    end

    redirect_to unbound_requests_path(mapping_result)
  end


  # confirm_reservations: responsible for making reservation related to the unbound requests
  # Checks if there is a forgotten timeslot and returns relative message
  # If everything is OK, calls reserveNode with the appropriate parameters 
  def confirm_reservations
    puts "Auta einai ta params"
    puts params[:user_slice]
    puts params[:reservations].inspect

    params[:reservation]

    reservations = []
    params[:reservations].each do |element|
      reservations << eval(element) 
    end

    old_timeslot = false
    reservations.each do |reservation|
      if reservation["valid_from"] <= Time.zone.now.to_s
        old_timeslot = true
        break
      end
    end
      
    if old_timeslot == true
      redirect_to :back
      flash[:danger] = "Your time is old. Please make a new request." 
    else
      array_with_reservations = []
      reservations.each do |element|

        h = Hash.new
        h = {"valid_from" => element["valid_from"], "valid_until"=> element["valid_until"], "resources"=> [element["uuid"]] }
        if array_with_reservations.length == 0
          array_with_reservations << h
        else
          flag = 0
          array_with_reservations.each do |reservation|
            if reservation["valid_from"] == element["valid_from"] && reservation["valid_until"] == element["valid_until"] && !reservation["resources"].include?(element["uuid"])
              reservation["resources"] << element["uuid"]
              flag =1
              break 
            end                     
          end
        end
        if flag == 0
          array_with_reservations << h
        end
      end

      puts array_with_reservations

      results_of_reservations = []
      array_with_reservations.each do |reservation|
        results_of_reservations << reserveNode(reservation["resources"],params[:user_slice],reservation["valid_from"],reservation["valid_until"])
      end

      flash_msg = []
      results_of_reservations.each do |result|
        if !result.to_s.include?("OK")     
          flash_msg << result.to_s       
        end
      end      
      if flash_msg.length !=0
        flash[:danger] = flash_msg
      else
        flash[:success] = "Successful reservation!"
      end
      redirect_to unbound_requests_path
    end   
  end

  
  # my_reservations: creates a hash with keys the user's slices and values an array with the reservations of every slice 
  def my_reservations
    @slices = []
    @slices = getSlices
    puts @slices.inspect
    @my_reservations = Hash.new
    if @slices.length != 0    
      @slices.each do |slice|
        this_slice_leases = []
        this_slice_leases = getLeasesBySlice(slice)        
        #Sort my slices by valid_from
        this_slice_leases = this_slice_leases.sort_by{|hsh| hsh["valid_from"]}
        @my_reservations[slice] = this_slice_leases       
        # puts "my reservations "
        # puts @my_reservations.inspect
      end
    end
  end

  # cancel_reservation: responsible for canceling a reservation by calling cancelReservation
  def cancel_reservation
    lease_uuid = params[:lease_uuid]
    puts lease_uuid
    cancelReservation(lease_uuid)
    redirect_to my_reservations_path
  end


  # reservation is responsible for showing the scheduler to users.   
  def reservation 

    # check if user pass a date. if user select a date we present him/her the schedule according to this date
    # else we show the schedule of current date.
    # @date: variable that contains the given date or the current according to user's timezone

    if params[:start_date] == "" || params[:start_date] == nil
      @date = Time.zone.today.to_s
    else
      @date = params[:start_date].split(" ")[0]
    end

    node_obj = Nodes.new
    @resources_list_names = node_obj.get_resources_list_names
    @node_list = node_obj.get_node_list
    @user_slices = getSlices()
    @details_of_resources = node_obj.get_details_of_resources

    # columns: array with the times of a day. from 00:00 until 23:30. step = :30
    columns = Array.new(48)
    columns[0]= "Name"
    (0..47).each do |n|
      if (n % 2 == 0) 
        columns[n+1] = "#{n<20 ? "0#{n / 2}" : n / 2}:00"
      else
        columns[n+1] =  "#{n<20 ? "0#{n / 2}" : n / 2}:30"
      end
    end

    num = @resources_list_names.length
    # rows: a two dimension array filled with zero, except from the first column that is filled with the names of the resources
    rows = Array.new(num){Array.new(49,0)}

    $i=0

    while $i< num do
      rows[$i][0] = @resources_list_names[$i]
      $i +=1
    end

    # We have two cases.
    # if @date == Time.zone.today.to_s we shows the schedule of the next 24hours
    # else we shows the schedule for the selected date by the user
    if @date == Time.zone.today.to_s
      
      time_now =  Time.zone.now.to_s.split(" ")[1][0...-3]
      @tomorrow = (Time.zone.today + 1.day).to_s
      
      # today_and_tommorow_columns: table with first element the string "Name" and the rest elements are all times from the next half hour
      today_and_tommorow_columns = []
      today_and_tommorow_columns << "Name"
      columns.each do |element|
        if element > time_now && element != "Name"
          today_and_tommorow_columns << @date + " " + element 
        end
      end

      columns.each do |element|
        if element <= time_now && element != "Name"        
          today_and_tommorow_columns << @tomorrow + " " + element
        end
      end

      # @reservation_table: a table with hashes.
      # every element is a hash with the Name of the resource and the reserved timeslots
      # ex {"Name"=>"node016", "2014-11-11 21:00"=>0, "2014-11-11 21:30"=>0, "2014-11-11 22:00"=>0, "2014-11-11 22:30"=>0, 
      # "2014-11-11 23:00"=>0, "2014-11-11 23:30"=>0, "2014-11-12 00:00"=>0, "2014-11-12 00:30"=>0, "2014-11-12 01:00"=>0, "2014-11-12 01:30"=>0,
      #  "2014-11-12 02:00"=>0, "2014-11-12 02:30"=>1, "2014-11-12 03:00"=>0, "2014-11-12 03:30"=>0, "2014-11-12 04:00"=>0, "2014-11-12 04:30"=>0,
      #   "2014-11-12 05:00"=>0, "2014-11-12 05:30"=>0, "2014-11-12 06:00"=>0, "2014-11-12 06:30"=>0, "2014-11-12 07:00"=>0, "2014-11-12 07:30"=>0, 
      #   "2014-11-12 08:00"=>0, "2014-11-12 08:30"=>0, "2014-11-12 09:00"=>0, "2014-11-12 09:30"=>0, "2014-11-12 10:00"=>0, "2014-11-12 10:30"=>0,
      #    "2014-11-12 11:00"=>0, "2014-11-12 11:30"=>0, "2014-11-12 12:00"=>0, "2014-11-12 12:30"=>0, "2014-11-12 13:00"=>0, "2014-11-12 13:30"=>0, 
      #    "2014-11-12 14:00"=>0, "2014-11-12 14:30"=>0, "2014-11-12 15:00"=>0, "2014-11-12 15:30"=>0, "2014-11-12 16:00"=>0, "2014-11-12 16:30"=>0, 
      #    "2014-11-12 17:00"=>0, "2014-11-12 17:30"=>0, "2014-11-12 18:00"=>0, "2014-11-12 18:30"=>0, "2014-11-12 19:00"=>0, "2014-11-12 19:30"=>0, 
      #    "2014-11-12 20:00"=>0, "2014-11-12 20:30"=>0}
      # if there is a reservation for a specifiv timeslot we set the relative timeslot with 1 otherwise we have 0 (default value)

      @reservation_table = rows.map{|r| Hash[ *today_and_tommorow_columns.zip(r).flatten ] }     

      @today_leases = getLeasesByDate(Time.zone.today.to_s)
      @tomorrow_leases = getLeasesByDate(@tomorrow)
      

      @reservation_table.each do |iterate|
        # filling 1 to @reservation_table for the reserved resources for the "today" date 
        @today_leases.each do |today_lease|

          date_from = today_lease["valid_from"].split(' ')[0]
          date_until = today_lease["valid_until"].split(' ')[0]
          time_from = today_lease["valid_from"].split(' ')[1][0...-3]
          time_until = today_lease["valid_until"].split(' ')[1][0...-3]
          
          # use roundTimeFrom and roundTimeUntil for times between :00-:30 such as :15 (for minutes)
          time_from = roundTimeFrom(time_from)
          time_until = roundTimeUntil(time_until)

          #Auto me to prev einai  gia na apofeugw ta diplwtupa (den einai aparaithto)
          prev_component = ""
          today_lease["components"].each do |component|
            #puts (@date + " " + component["component"]["name"]).to_s
            if component["component"]["name"] != prev_component && iterate["Name"] == component["component"]["name"]
              if date_from == date_until
                if time_from < time_now && time_until > time_now
                  iterate.each_key do |key|
                    if key != "Name"
                      key_time = key.split(" ")[1] 
                      #puts key_time  
                    
                      if key_time > time_now && key_time < time_until 
                        iterate[key] = 1
                      end
                    end
                  end
                elsif time_from > time_now
                    iterate.each_key do |key|
                      if key != "Name"
                        key_time = key.split(" ")[1]   
                      
                        if key_time >= time_from && key_time < time_until 
                          iterate[key] = 1
                        end
                      end
                    end
                end  
              elsif date_from < date_until
                if @date == date_from
                  if time_from > time_now 
                    iterate.each_key do |key|
                      if key != "Name"
                        key_time = key.split(" ")[1]   
                                          
                        if key_time >= time_from 
                          iterate[key] = 1
                        end
                      end
                    end
                  else
                    iterate.each_key do |key|
                      if key != "Name"
                        key_time = key.split(" ")[1]   
                                         
                        if key_time > time_now 
                          iterate[key] = 1
                        end 
                      end
                    end    
                  end
                elsif @date == date_until
                  if time_until > time_now
                    iterate.each_key do |key|
                      if key != "Name"
                        key_time = key.split(" ")[1]   
                                          
                        if key_time > time_now && key_time < time_until 
                          iterate[key] = 1
                        end
                      end
                    end
                  end
                else
                  iterate.each_key do |key| 
                    if key != "Name"
                      key_time = key.split(" ")[1]   
                                                             
                      if key_time > time_now
                        iterate[key] = 1
                      end
                    end
                  end
                end
              end

              #puts component["component"]["name"]
              prev_component = component["component"]["name"]
            end
          end
        end
      end
      #puts @reservation_table
      @reservation_table.each do |iterate|
        # filling 1 to @reservation_table for the reserved resources for the "tommorow" date 
        
        #Se auth thn periptwsh skeftomai to <= tou time_now san to orio tou programmatos 
        #pou tha emfanisw sto xrhsh 
        @tomorrow_leases.each do |tomorrow_lease|

          date_from = tomorrow_lease["valid_from"].split(' ')[0]
          date_until = tomorrow_lease["valid_until"].split(' ')[0]
          time_from = tomorrow_lease["valid_from"].split(' ')[1][0...-3]
          time_until = tomorrow_lease["valid_until"].split(' ')[1][0...-3]


          time_from = roundTimeFrom(time_from)
          time_until = roundTimeUntil(time_until)

          #Auto me to prev einai proswrinh lush gia na apofeugw ta diplwtupa 
          prev_component = ""
          tomorrow_lease["components"].each do |component|
            if component["component"]["name"] != prev_component && iterate["Name"] == component["component"]["name"]              
              if date_from == date_until
                if time_from < time_now && time_until <= time_now
                  iterate.each_key do |key|
                    if key != "Name"
                      key_time = key.split(" ")[1]                         
                      if key_time >= time_from && key_time < time_until
                        iterate[key] = 1
                      end   
                    end
                  end 
                elsif time_from <= time_now && time_until > time_now
                  iterate.each_key do |key|
                    if key != "Name"
                      key_time = key.split(" ")[1]                        
                      if key_time >= time_from && key_time <= time_now
                        iterate[key] = 1
                      end   
                    end
                  end                                       
                end
              elsif date_from < date_until
                if @tomorrow == date_from
                  if time_from <= time_now
                    iterate.each_key do |key|
                      if key != "Name"
                        key_time = key.split(" ")[1]                         
                        if key_time >= time_from && key_time <= time_now 
                          iterate[key] = 1
                        end  
                      end 
                    end  
                  end
                elsif @tomorrow == date_until
                  if time_until <= time_now
                    iterate.each_key do |key|
                      if key != "Name"
                        key_time = key.split(" ")[1]                         
                        if key_time < time_until  
                          iterate[key] = 1
                        end 
                      end  
                    end
                  else
                    iterate.each_key do |key|
                      if key != "Name"
                        key_time = key.split(" ")[1]                         
                        if key_time <= time_now  
                          iterate[key] = 1
                        end 
                      end  
                    end
                  end
                else
                  iterate.each_key do |key| 
                    if key != "Name"
                      key_time = key.split(" ")[1]                                                              
                      if key_time <= time_now
                        iterate[key] = 1
                      end
                    end
                  end      
                end
              end
              puts component["component"]["name"]
              prev_component = component["component"]["name"]
            end
          end
        end
      end
      puts @reservation_table
    else
      # Same way as above but only for the given date
      @today_leases = getLeasesByDate(@date)

      today_columns = []
      today_columns << "Name"
      columns.each do |element|
        if element != "Name"
          today_columns << @date + " " + element 
        end
      end

      @reservation_table = rows.map{|r| Hash[ *today_columns.zip(r).flatten ] }
      #puts @reservation_table.inspect  
      # puts @today_leases.inspect
      puts @today_leases.inspect

      @reservation_table.each do |iterate|
        @today_leases.each do |t_lease|


          date_from = t_lease["valid_from"].split(' ')[0]
          date_until = t_lease["valid_until"].split(' ')[0]
          time_from = t_lease["valid_from"].split(' ')[1][0...-3]
          time_until = t_lease["valid_until"].split(' ')[1][0...-3]



          time_from = roundTimeFrom(time_from)
          time_until = roundTimeUntil(time_until)

          prev_component = ""
          t_lease["components"].each do |component|
            if component["component"]["name"] != prev_component && iterate["Name"] == component["component"]["name"]
              if date_from == date_until
                iterate.each_key do |key|
                  if key != "Name"
                    key_time = key.split(" ")[1]
                    if key_time >= time_from && key_time < time_until && key != "Name" 
                      iterate[key] = 1
                    end
                  end
                end
              elsif date_from < date_until
                if @date == date_from
                  iterate.each_key do |key|
                    if key != "Name"
                      key_time = key.split(" ")[1]
                      if key_time >= time_from && key != "Name" 
                        iterate[key] = 1
                      end
                    end
                  end
                elsif @date == date_until
                  iterate.each_key do |key|
                    if key != "Name"
                      key_time = key.split(" ")[1]
                      if key_time < time_until  
                        iterate[key] = 1
                      end
                    end
                  end
                else
                  iterate.each_key do |key|
                    if key != "Name"
                      key_time = key.split(" ")[1]
                      if key != "Name"  
                        iterate[key] = 1
                      end
                    end
                  end
                end             
              end           
            end

            puts component["component"]["name"]
            prev_component = component["component"]["name"]
          end
        end        
      end
    end

  end

  # responsible for making reservations
  def make_reservation
    
    node_obj = Nodes.new
    hash_details_of_resources = node_obj.get_details_of_resources
    
    # finds which resources are for reservation
    ids = []
    reservations = []
    reservations = params[:reservations]
    # puts "Autes einai oi krathseis pou thelw na kanw"
    # puts reservations

    # control for empty request for reservation
    reservation_table = []
    if reservations == nil 
      redirect_to :back
      flash[:danger] = "You must select a timeslot to make a reservation. Please try again" 
    else

      #control for up to 8 timeslots reservation 

      hash_num_limition = Hash.new
      reservations.each do |element|
        hash_num_limition[element.split('/')[0]] = 0 
      end

      reservations.each do |element|
        hash_num_limition[element.split('/')[0]] = hash_num_limition[element.split('/')[0]]+1
      end

      flag_limit = false
      hash_num_limition.each_value do |value|
        if value>8
          flag_limit = true
          break
        end
      end

      if flag_limit == true
        redirect_to :back
      flash[:danger] = "Please choose at most 8 timeslots for every resource." 
      else
        #control for forgotten timeslots 
        old_timeslot = false
        reservations.each do |reservation|
          if reservation.split('/')[1] <= Time.zone.now.to_s[0...-9]
            old_timeslot = true
            break
          end
        end
        
        if old_timeslot == true
          redirect_to :back
          flash[:danger] = "Please select a time from now on" 
        else

          
          # Checks if there is two different dates of reservations (case of 24hours schedule) and keeps the shorter
          reservation_date_num = 0
          reservation_date = ""
          reservations.each do |reservation|
            date = reservation.split('/')[1][0...-6]
            if date != reservation_date
              if date < reservation_date && reservation_date != ""
                reservation_date = date
                reservation_date_num +=1
              elsif reservation_date == ""
                reservation_date = date
                reservation_date_num +=1
              end
              
            end
          end

          reservations.each do |reservation|
            if !ids.include?(reservation.split('/')[0])
              ids << reservation.split('/')[0]
            end
          end

          puts "reservation_date_num"
          puts reservation_date_num

          # constructs a table with the reservations. 1 for selected timeslot and 0 for non-selected
          if reservation_date_num >= 2 || reservation_date == Time.zone.today.to_s

            today = Time.zone.today.to_s
            tomorrow = (Time.zone.today + 1.day).to_s
            time_now =  Time.zone.now.to_s.split(" ")[1][0...-3]

            #Upologismos gia sthles
            columns = Array.new(48)
            columns[0]= "Name"
            (0..47).each do |n|
              if (n % 2 == 0) 
                columns[n+1] = "#{n<20 ? "0#{n / 2}" : n / 2}:00"
              else
                columns[n+1] =  "#{n<20 ? "0#{n / 2}" : n / 2}:30"
              end
            end

            today_and_tommorow_columns = []
            today_and_tommorow_columns << "Name"

            columns.each do |element|
              if element > time_now && element != "Name"
                today_and_tommorow_columns << today + " " + element 
              end
            end

            columns.each do |element|
              if element <= time_now && element != "Name"        
                today_and_tommorow_columns << tomorrow + " " + element
              end
            end

            #Upologismos gia rows
            rows = Array.new(ids.length){Array.new(49,0)}
            rows.each_index do |i|
              rows[i][0] = ids[i]
            end

            reservation_table = rows.map{|r| Hash[ *today_and_tommorow_columns.zip(r).flatten ] }
          else
            ids.each_index do |i|
              h = Hash.new
              r_name = ids[i]
              h["Name"] = r_name
              (0..47).each do |n|
                if (n % 2 == 0) 
                  h["#{reservation_date}#{n<20 ? " 0#{n / 2}" : " #{n / 2}"}:00"] = 0
                else
                  h["#{reservation_date}#{n<20 ? " 0#{n / 2}" : " #{n / 2}"}:30"] =  0
                end
              end
              #if the last half hour of a day selected, we reserve a node until "23:59" 
              h[reservation_date + " 23:59"] = 0
              reservation_table << h
            end
          end
            #Sumplhrwnw o kathe hash me tis krathseis 
            reservation_table.each do |element|
              reservations.each do |reservation|
                if reservation.split('/')[0] == element["Name"]
                  element[reservation.split('/')[1]] =1
                end
              end
            end
            puts ids

            
            # array_with_reservations: table filled with hashes of the reservations to be done 
            array_with_reservations = []
            num = 0
            #Compute valid_from and valid_until for each reservation request 
            valid_from = ""
            valid_until = ""
            puts "Auto einai to reservation table afou to gemisw"
            puts reservation_table.inspect
            reservation_table.each do |element|
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

                    valid_from = valid_from + ":00 " #+ Time.zone.now.to_s.split(' ')[2]
                    valid_from = Time.zone.parse(valid_from)
                    valid_until = valid_until + ":00 " #+ Time.zone.now.to_s.split(' ')[2]
                    valid_until = Time.zone.parse(valid_until)
                    #reserveNode(node_list_uuids[element["Name"]],params[:user_slice],valid_from,valid_until)
                    
                    h = Hash.new
                    h = {"valid_from" => valid_from, "valid_until"=> valid_until, "resources"=> [hash_details_of_resources[element["Name"]]["uuid"]] }
                    if array_with_reservations.length == 0
                      array_with_reservations << h
                    else
                      flag = 0
                      array_with_reservations.each do |reservation|
                        if reservation["valid_from"] == valid_from && reservation["valid_until"] == valid_until && !reservation["resources"].include?(hash_details_of_resources[element["Name"]]["uuid"])
                          reservation["resources"] << hash_details_of_resources[element["Name"]]["uuid"]
                          flag =1
                          break                      
                        end
                      end
                      if flag == 0
                        array_with_reservations << h
                      end
                    end
                    puts "Tha kanw krathsh me valid_from"
                    puts valid_from
                    puts "kai valid_until"
                    puts valid_until
                    # puts "Gia ton "+element["Name"] + "me uuid=" + @node_list_uuids[element["Name"]]
                    num = 0
                  end
                end
              end
            end
            puts ""
            puts "Auto einai to array me ta reservation pou prepei na ginoun"
            puts array_with_reservations

            # Making reservations
            results_of_reservations = []
            array_with_reservations.each do |reservation|
              results_of_reservations << reserveNode(reservation["resources"],params[:user_slice],reservation["valid_from"],reservation["valid_until"])
            end
            
            flash_msg = []
            results_of_reservations.each do |result|
              if !result.to_s.include?("OK")     
                flash_msg << result.to_s       
              end
            end      
            if flash_msg.length !=0
              flash[:danger] = flash_msg
            else
              flash[:success] = "Successful reservation!"
            end
            redirect_to :back 
        end

      end

      
    end 
  end

end
