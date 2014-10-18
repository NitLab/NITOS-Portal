class SchedulerController < ApplicationController
  before_action :signed_in_user
  around_filter :set_timezone
  include SchedulerHelper
  require "momentjs-rails"

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

  def make_unbound_requests
    puts params
    
    puts params[:number_of_nodes]
    puts params[:number_of_channels]
    puts params[:duration_t1]
    puts params[:duration_t2]
    puts params[:start_date]
    puts params[:start_date_2]
    puts params[:domain1]
    puts params[:domain2]

    mapping_result = []

    if params[:number_of_nodes] == "" && params[:number_of_channels] == ""
      flash[:danger] = "You must set number of nodes or channels tou make an unbound request!"
    else
      mapping_result = unboundRequest(params)
      puts "H sunarthsh mou epestrepse "
      puts mapping_result
    end

    redirect_to unbound_requests_path(mapping_result)
  end


  def confirm_reservations
    puts "Auta einai ta params"
    puts params[:user_slice]
    puts params[:reservations].inspect

    reservations = []
    params[:reservations].each do |element|
      reservations << eval(element) 
    end

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

    array_with_reservations.each do |reservation|
          reserveNode(reservation["resources"],params[:user_slice],reservation["valid_from"],reservation["valid_until"])
    end
    redirect_to unbound_requests_path
  end

  # Dhmiourgw ena hash pou exei san key ta slices tou user kai san values tou kathe key enan pinaka me krathseis gia to kathe slice
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

  def cancel_reservation
    lease_uuid = params[:lease_uuid]
    puts lease_uuid
    cancelReservation(lease_uuid)
    redirect_to my_reservations_path
  end

  def scheduler 
    puts "Sxetika me tis wres"
    puts "Time.zone.now"
    puts Time.zone.now
    puts "Time.now"
    puts Time.now
    puts "2.hours.ago"
    puts 2.hours.ago
    puts "1.day.from_now"
    puts 1.day.from_now
    puts "Date.today"
    puts Date.today
    puts "Time.zone.today"
    puts Time.zone.today
    puts "Time.zone.today - 1.day"
    puts Time.zone.today - 1.day
    # puts "Date.today.to_time_in_current_zone"
    # puts Date.today.to_time_in_current_zone
    puts "Date.current"
    puts Date.current
    puts "Time.zone.today"
    puts Time.zone.today
    

    if params[:start_date] != nil
      puts params[:start_date]
    end

    example = []
    example = getLeasesByAccount

    @slices = []
    @slices = getSlices

    # reserveNode(["77879ad1-b6ee-419c-ae70-05c19f4ea745"],"ardadouk","2014-09-30 15:15:00 +0000","2014-09-30 19:15:00 +0000")
    # reserveNode(["77879ad1-b6ee-419c-ae70-05c19f4ea745"],"ardadouk","2014-09-30 20:00:00 +0000","2014-09-30 22:30:00 +0000")
    # reserveNode(["a1d43ca1-8798-4564-8a63-37dd95a15ded"],"ardadouk","2014-09-30 20:45:00 +0000","2014-09-30 22:45:00 +0000")
  end

  def reservation 

    puts "Testing times"

    if params[:start_date] == "" || params[:start_date] == nil
      @date = Date.today.to_s
    else
      @date = params[:start_date]
    end
    puts @date
    puts params[:start_date]
    puts "h shmerinh hmeromhnia"
    puts Time.zone.today.to_s

    node_obj = Nodes.new
    @node_list = node_obj.get_node_list
    @node_list_names = node_obj.get_node_list_names
    @user_slices = getSlices()
    @details_of_nodes = node_obj.get_details_of_nodes

    columns = Array.new(48)
    columns[0]= "Name"
    (0..47).each do |n|
      if (n % 2 == 0) 
        columns[n+1] = "#{n<20 ? "0#{n / 2}" : n / 2}:00"
      else
        columns[n+1] =  "#{n<20 ? "0#{n / 2}" : n / 2}:30"
      end
    end

    num = @node_list_names.length
    rows = Array.new(num){Array.new(49,0)}

    $i=0

    while $i< num do
      rows[$i][0] = @node_list_names[$i]
      $i +=1
    end

    # @date = (Date.civil(params[:start_date][:year].to_i,params[:start_date][:month].to_i,
    #  params[:start_date][:day].to_i)).to_s

    
    if @date == Date.today.to_s
      #Emfanise pinaka gia tis epomenes 24 wres
      time_now =  Time.now.to_s.split(" ")[1][0...-3]
      # @tomorrow = ((Date.civil(params[:start_date][:year].to_i,params[:start_date][:month].to_i,
      #      params[:start_date][:day].to_i)) + 1).to_s
      @tomorrow = (Date.today + 1.day).to_s

      puts time_now
      puts @tomorrow

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

      @reservation_table = rows.map{|r| Hash[ *today_and_tommorow_columns.zip(r).flatten ] }
      
      @today_leases = getLeasesByDate(@date)
      @tomorrow_leases = getLeasesByDate(@tomorrow)

      puts "today leases"
      puts @today_leases
      puts "tomorrow leases"
      puts @tomorrow_leases

      puts @reservation_table
      @reservation_table.each do |iterate|
        @today_leases.each do |today_lease|
          date_from = today_lease["valid_from"].split('T')[0]
          date_until = today_lease["valid_until"].split('T')[0]
          time_from = today_lease["valid_from"].split('T')[1][0...-4]
          time_until = today_lease["valid_until"].split('T')[1][0...-4]
          # puts "auta eunau ta dedomena mou "
          # puts date_from
          # puts date_until
          # puts time_from
          # puts time_until
          # puts @date

          time_from = roundTimeFrom(time_from)
          time_until = roundTimeUntil(time_until)

          #Auto me to prev einai proswrinh lush gia na apofeugw ta diplwtupa 
          prev_component = ""
          today_lease["components"].each do |component|
            puts (@date + " " + component["component"]["name"]).to_s
            if component["component"]["name"] != prev_component && iterate["Name"] == component["component"]["name"]
              if date_from == date_until
                if time_from < time_now && time_until > time_now
                  iterate.each_key do |key|
                    if key != "Name"
                      key_time = key.split(" ")[1] 
                      puts key_time  
                    
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

              puts component["component"]["name"]
              prev_component = component["component"]["name"]
            end
          end
        end
      end
      #puts @reservation_table
      @reservation_table.each do |iterate|
        #Edw prepei na kanw gia to tomorrow 
        #Se auth thn periptwsh skeftomai to <= tou time_now san to orio tou programmatos 
        #pou tha emfanisw sto xrhsh 
        @tomorrow_leases.each do |tomorrow_lease|
          date_from = tomorrow_lease["valid_from"].split('T')[0]
          date_until = tomorrow_lease["valid_until"].split('T')[0]
          time_from = tomorrow_lease["valid_from"].split('T')[1][0...-4]
          time_until = tomorrow_lease["valid_until"].split('T')[1][0...-4]
          # puts "auta eunau ta dedomena mou "
          # puts date_from
          # puts date_until
          # puts time_from
          # puts time_until
          # puts @date

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
    else
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
          date_from = t_lease["valid_from"].split('T')[0]
          date_until = t_lease["valid_until"].split('T')[0]
          time_from = t_lease["valid_from"].split('T')[1][0...-4]
          time_until = t_lease["valid_until"].split('T')[1][0...-4]
          puts date_from
          puts date_until
          puts time_from
          puts time_until
          puts @date

          time_from = roundTimeFrom(time_from)
          time_until = roundTimeUntil(time_until)

          puts "Ta stroggulopoihmena times einai"
          puts time_from
          puts time_until

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

    #puts "Gia na doume ti kaname....Good luck"
    #puts @reservation_table
  end

  # def reservation
    
  #   columns = Array.new(48)
  #   columns[0]= "Name"

  #   (0..47).each do |n|
  #     if (n % 2 == 0) 
  #       columns[n+1] = "#{n<20 ? "0#{n / 2}" : n / 2}:00"
  #     else
  #       columns[n+1] =  "#{n<20 ? "0#{n / 2}" : n / 2}:30"
  #     end
  #   end

  #   #puts columns.inspect

    
  #   node_obj = Nodes.new
  #   @date = (Date.civil(params[:start_date][:year].to_i,params[:start_date][:month].to_i, params[:start_date][:day].to_i)).to_s
  #   puts "H hmeromhnia einai " 
  #   puts @date 
  #   if @date == Date.today.to_s
  #     puts "Geia sas "
  #   end
  #   @node_list = node_obj.get_node_list
  #   @node_list_names = node_obj.get_node_list_names
  #   #puts @node_list_uuids
  #   @user_slices = getSlices()
  #   #@leases = getLeases()
  #   @today_leases = getLeasesByDate(@date)

  #   num = @node_list_names.length

  #   rows = Array.new(num){Array.new(49,0)}

  #   $i=0

  #   while $i< num do
  #     rows[$i][0] = @node_list_names[$i]
  #     $i +=1
  #   end

  #   #puts rows.inspect

  #   @reservation_table = rows.map{|r| Hash[ *columns.zip(r).flatten ] }
  #   #puts @reservation_table.inspect  
  #   # puts @today_leases.inspect
  #   puts @today_leases.inspect

  #   @reservation_table.each do |iterate|
  #     @today_leases.each do |t_lease|
  #       date_from = t_lease["valid_from"].split('T')[0]
  #       date_until = t_lease["valid_until"].split('T')[0]
  #       time_form = t_lease["valid_from"].split('T')[1][0...-4]
  #       time_until = t_lease["valid_until"].split('T')[1][0...-4]
  #       puts date_from
  #       puts date_until
  #       puts time_form
  #       puts time_until
  #       puts @date


  #       if iterate["Name"] == t_lease["components"][0]["component"]["name"]
  #         if date_from == date_until
  #           iterate.each_key do |key|
  #             if key >= time_form && key < time_until && key != "Name" 
  #               iterate[key] = 1
  #             end
  #           end
  #         elsif date_from < date_until
  #           if @date == date_from
  #             iterate.each_key do |key|
  #               if key >= time_form && key != "Name" 
  #                 iterate[key] = 1
  #               end
  #             end
  #           elsif @date == date_until
  #             iterate.each_key do |key|
  #               if key < time_until  
  #                 iterate[key] = 1
  #               end
  #             end
  #           else
  #             iterate.each_key do |key|
  #               if key != "Name"  
  #                 iterate[key] = 1
  #               end
  #             end
  #           end             
  #         end
          
  #       end
  #     end
      
  #   end
  #   puts @reservation_table
        
  # end

  def make_reservation
    #Apo dw kai katw einai to palio resevation 
    node_obj = Nodes.new
    node_list_uuids = node_obj.get_node_list_uuids
    # Vriskw poioi komvoi einai pros krathsh 
    ids = []
    reservations = []
    reservations = params[:reservations]
    reservation_table = []
    if reservations == nil 
      redirect_to :back
      flash[:danger] = "You must select a timeslot to make a reservation. Please try again" 
    else
      puts "Autes einai oi krathseis pou thelw na kanw "
      puts reservations
      #puts params[:user_slice]

      #@date =  (Date.civil(params[:start_date][:year].to_i,params[:start_date][:month].to_i, params[:start_date][:day].to_i)).to_s
      
      #Vriskw an exw panw apo 2 hmeromhnies gia krathseis kai krataw sto reservation_date th mikroterh

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

      if reservation_date_num >= 2 || reservation_date == Date.today.to_s

        today = Date.today.to_s
        tomorrow = (Date.today + 1).to_s
        time_now =  Time.now.to_s.split(" ")[1][0...-3]

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

        
        #Vriskw valid_fom kai valid_until gia kathe aithsh 
        array_with_reservations = []
        num = 0
        valid_from = ""
        valid_until = ""
        puts reservation_table
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
                valid_from = valid_from + ":00 +0000"
                valid_until = valid_until + ":00 +0000"
                #reserveNode(node_list_uuids[element["Name"]],params[:user_slice],valid_from,valid_until)
                
                h = Hash.new
                h = {"valid_from" => valid_from, "valid_until"=> valid_until, "resources"=> [node_list_uuids[element["Name"]]] }
                if array_with_reservations.length == 0
                  array_with_reservations << h
                else
                  flag = 0
                  array_with_reservations.each do |reservation|
                    if reservation["valid_from"] == valid_from && reservation["valid_until"] == valid_until && !reservation["resources"].include?(node_list_uuids[element["Name"]])
                      reservation["resources"] << node_list_uuids[element["Name"]]
                      flag =1
                      break                      
                    end
                  end
                  if flag == 0
                    array_with_reservations << h
                  end
                end
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
        # puts ""
        # puts "Auto einai to array me ta reservation pou prepei na ginoun"
        # puts array_with_reservations

        array_with_reservations.each do |reservation|
          reserveNode(reservation["resources"],params[:user_slice],reservation["valid_from"],reservation["valid_until"])
        end
      redirect_to :back 
    end 
  end

  private

  def set_timezone
    default_timezone = Time.zone
    client_timezone  = cookies[:timezone]
    puts "Na to to coooookie"
    puts client_timezone
    Time.zone = client_timezone if client_timezone.present?
    yield
  ensure
    Time.zone = default_timezone
  end

end
