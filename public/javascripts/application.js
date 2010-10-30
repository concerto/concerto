// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

$(document).ready(function () {
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
});
