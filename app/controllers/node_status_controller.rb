class NodeStatusController < ApplicationController
  include NodeStatusHelper
  include SchedulerHelper
  before_action :signed_in_user
  around_filter :set_timezone
  

  def node_status
    node_obj = Nodes.new
    # @node_list: a table with the numbers of nodes. ex: for node 
    # node121 we add 121. Used in node status for turning ON/OFF/reset a node
    @node_list = node_obj.get_node_list

    @user_slices = []
    @user_slices = getSlices

    # this_account_reservations: hash with slices of account as keys and leases of each slice as value
    this_account_reservations = Hash.new
    if @user_slices.length != 0    
      @user_slices.each do |slice|
        this_slice_leases = []
        this_slice_leases = getLeasesBySlice(slice)        

        #Sort my slices by valid_from
        this_slice_leases = this_slice_leases.sort_by{|hsh| hsh["valid_from"]}
        this_account_reservations[slice] = this_slice_leases       
        #puts "this_account_reservations "
        #puts this_account_reservations.inspect
      end
    end

    time = Time.zone.now.to_s
    
    # @hash_reserved_nodes: hash with slices of account as keys and reserved node for this slice as value
    @hash_reserved_nodes = Hash.new
    
    this_account_reservations.each do |key,value|
      temp = []
      @node_list.each do |node|       
        value.each do |reservation|
            reservation["components"].each do |element|
              if element["component"]["name"].to_s.start_with?("node") && element["component"]["name"].to_s[-3,3] == node && reservation["valid_from"].to_s<= time && reservation["valid_until"].to_s > time
                temp << node
                break
              end
            end
        end
        
      end
      @hash_reserved_nodes[key] = temp
    end

    puts " @hash_reserved_nodes"
    puts  @hash_reserved_nodes

    @reserved_nodes = []
    @node_list.each do |node|
      this_account_reservations.each_value do |value|
        value.each do |reservation|
            reservation["components"].each do |element|
              if element["component"]["name"].to_s[-3,3] == node && reservation["valid_from"].to_s<= time && reservation["valid_until"].to_s > time
                @reserved_nodes << node
                break
              end
            end
        end
      end
    end
    puts "Autoi einai oi reserved komvoi"
    puts @reserved_nodes  
  end

  # set_node_on: triggered when ON button clicked.
  # we check if user has the right to make this action and if not we alert him a relative message
  def set_node_on
    node_id = params[:node_id]
    #puts node_id

    if hasRightForNode?(node_id)
      setNodeON(node_id)
      respond_to do |format|
        format.json {render nothing: true}
      end      
    else
      render :js => "alert('You are not legal to make this action')"
    end
  end

  # set_node_off: triggered when OFF button clicked.
  # we check if user has the right to make this action and if not we alert him a relative message
  def set_node_off
    node_id = params[:node_id]
    puts node_id    
    if hasRightForNode?(node_id)
      setNodeOFF(node_id)
      respond_to do |format|
        format.json {render nothing: true}
      end      
    else
      render :js => "alert('You are not legal to make this action')"
    end
  end

  # reset_node: triggered when Reset button clicked.
  # we check if user has the right to make this action and if not we alert him a relative message
  def reset_node
    node_id = params[:node_id]    
    if hasRightForNode?(node_id)
      resetNode(node_id)
      respond_to do |format|
        format.json {render nothing: true}
      end      
    else
      render :js => "alert('You are not legal to make this action')"
    end
  end

end
