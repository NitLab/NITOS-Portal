class StaticPagesController < ApplicationController

  include StaticPagesHelper

  def home
  end

  def about
  end

  def your_ssh_keys
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
    
    #redirect_to node_status_path 
  end

  def set_node_off
    node_id = params[:node_id]
    puts node_id
    setNodeOFF(node_id)
    respond_to do |format|
      format.json {render nothing: true}
    end
    
    #redirect_to node_status_path
  end

  def reset_node
    node_id = params[:node_id]
    resetNode(node_id)
    respond_to do |format|
      format.json {render nothing: true}
    end

  end

  
end
