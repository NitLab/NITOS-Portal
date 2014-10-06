// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require bootstrap.min
//= require moment
//= require bootstrap-datetimepicker
//= require turbolinks
//= require_tree .
//= require websocket_rails/main


var dispatcher = new WebSocketRails('localhost:3000/websocket');
channel = dispatcher.subscribe('nodes');

var temp = 'status'
channel.bind(temp, function(temp) {
  var node = temp["node"];
  //$("#node"+node).html(temp["response"]+"!");
  if (temp["response"] == "on"){
  	$("#node_"+node).css("background", "#4ccabf");
    $("#on_"+node).prop('disabled', true);
    $("#off_"+node).prop('disabled', false);
    $("#reset"+node).prop('disabled', false);
  }else if(temp["response"] == "off"){
  	$("#node_"+node).css("background", "#bec3c7 ");
    $("#on_"+node).prop('disabled', false);
    $("#off_"+node).prop('disabled', true);
    $("#reset"+node).prop('disabled', true);
  }else{
  	$("#node_"+node).css("background", "white");
  }
})

