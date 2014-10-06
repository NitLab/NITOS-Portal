class NodeStatusController < ApplicationController
  before_action :signed_in_user
  include NodeStatusHelper
  include SchedulerHelper

  def node_status
    @user_slices = []
    @user_slices = getSlices
    @my_reservations = Hash.new
    if @user_slices.length != 0    
      @user_slices.each do |slice|
        this_slice_leases = []
        this_slice_leases = getLeasesBySlice(slice)
        
        @my_reservations[slice] = this_slice_leases
        
        puts "my reservations "
        puts @my_reservations.inspect
      end
    end

    
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

end
