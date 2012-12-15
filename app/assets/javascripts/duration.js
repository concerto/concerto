function addDurationUi() {

  $("form .duration").each(function() {
    var duration_elem = $(this).find(".duration_range");
    
    $(duration_elem).rangeinput().hide();
    var range_elem = $(this).find(":range");
    var handle_elem = $(this).find(".handle");
    var api = $(range_elem).data("rangeinput");

    seconds = api.getValue();
    seconds = seconds+"s";
    $(handle_elem).html(seconds);

    $(range_elem).change(function() {
      seconds = api.getValue();
      seconds = seconds+"s";
      $(handle_elem).html(seconds);
    });
    $(range_elem).bind('onSlide', function() {
      seconds = api.getValue();
      seconds = seconds+"s";
      $(handle_elem).html(seconds);
    });
    
  });
  
}

function initDuration(){
  if($('form .duration').length > 0){
    addDurationUi();
  }
}

$(document).ready(initDuration);
