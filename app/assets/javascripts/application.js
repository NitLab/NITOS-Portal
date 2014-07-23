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
//= require bootstrap
//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap
//= require turbolinks
//= require_tree .
//= require websocket_rails/main


var dispatcher = new WebSocketRails('localhost:3000/websocket');
channel = dispatcher.subscribe('nodes');

// var node_list = getNodeList();
// var element;
// for (i=0; i < node_list.length; i++){
//     console.log(node_list.length);
//     console.log(element["name"]);

//     var fact = element["name"];
//     channel.bind(fact, function(temp) {
		  
// 	if (temp["response"] == "on"){
// 		 $("#node_<%fact%>").css("background", "#00FFCC");
// 		  }else if(temp["response"] == "off"){
// 		  	$("#node_<%fact%>").css("background", "#989898 ");
// 		  }else{
// 		  	$("#node_<%fact%>").css("background", "white");
// 		  }
// 		})
// }


//   $(document).ready(function(){
//     console.log(node_list.length);
//     console.log(node_list);
//     var element = node_list;
// }); 



var temp = 'status'
channel.bind(temp, function(temp) {
  var node = temp["node"]
  $("#node"+node).html(temp["response"]+"!");
  if (temp["response"] == "on"){
  	$("#node_"+node).css("background", "#00FFCC");
  }else if(temp["response"] == "off"){
  	$("#node_"+node).css("background", "#989898 ");
  }else{
  	$("#node_"+node).css("background", "white");
  }
})

// channel.bind('status121', function(temp) {
//   $("#test121").html(temp["response"]+"!");
//   if (temp["response"] == "on"){
//   	$("#node_121").css("background", "#00FFCC");
//   }else if(temp["response"] == "off"){
//   	$("#node_121").css("background", "#989898 ");
//   }else{
//   	$("#node_121").css("background", "white");
//   }
// })

