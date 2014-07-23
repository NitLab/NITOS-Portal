class StaticPagesController < ApplicationController

  include StaticPagesHelper

  def home
  end

  def about
  end

  def your_ssh_keys
  end

  def node_status
  end

  def set_node_on
    node_id = params[:node_id]
    puts node_id
    setNodeON(node_id)
    
    redirect_to node_status_path 
  end

  def set_node_off
    node_id = params[:node_id]
    puts node_id
    setNodeOFF(node_id)
    
    redirect_to node_status_path
  end

  
end
