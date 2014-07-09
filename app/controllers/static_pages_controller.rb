class StaticPagesController < ApplicationController

  include StaticPagesHelper

  require "httparty"
  require "json"

  def home
  end

  def about
  end

  def your_ssh_keys
  end

  def node_status
    @counter = 1
    while @counter < 5  do
      puts ("Kalhspera!")
      puts "#@counter"
      
      WebsocketRails[:nodes].trigger 'timh', @counter 
      @counter +=1
      sleep 3.0
    end    
      puts ("Geia sas")
    
  end

  def set_node_on
    node_id = params[:node_id]
    puts node_id
    setNodeON(node_id)
    
    redirect_to node_status_path :notice => "Node ON"
  end

  def set_node_off
    node_id = params[:node_id]
    puts node_id
    setNodeOFF(node_id)
    
    sleep 5.0
    redirect_to node_status_path :notice => "Node OFF"
  end

  
end
