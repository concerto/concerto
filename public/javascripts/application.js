// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function () {
  $('#start_time').timepicker();
  $("#end_time").timepicker();
  $('#start_date').datepicker();
  $('#end_date').datepicker();
	//Content grid/table switching
	$('a.update_holder').live('click', function(event){
		event.preventDefault();
		target_url = $(this).attr('href')
		$.ajax({
			url: target_url,
			dataType: "html",
			cache: false,
			success: function(data) {
				$("#content_holder").fadeOut(100, function(){
					$("#content_holder").html("").html(data).fadeIn('slow')
				});
			}
		});
	});

	$(":range").rangeinput();
	var api = $(":range").data("rangeinput");
	seconds = api.getValue();
	seconds = seconds+"s";
	$(".handle").html(seconds);
	$(":range").bind({onSlide:function () {
		seconds = api.getValue();
		seconds = seconds+"s";
		$(".handle").html(seconds);
	}});
	$(":range").change(function() {
		seconds = api.getValue();
		seconds = seconds+"s";
		$(".handle").html(seconds);
	});
	$(".inputrange").hide();
});
