function addDurationUi() {

  $("form .duration").each(function() {
    var duration_elem = $(this).find(".duration_range");
    
    $(duration_elem).rangeinput().hide();
    var range_elem = $(this).find(":range");
    var handle_elem = $(this).find(".handle");
    var api = $(range_elem).data("rangeinput");

    var updateSeconds = function() {
        $(handle_elem).html(I18n.t("js.duration.second", {count: api.getValue()}));
    };

    updateSeconds();

    $(range_elem).change(updateSeconds);
    $(range_elem).bind('onSlide', updateSeconds);
    
  });
  
}

function toggleDurationSelect() {
  $(".event-toggleDurationSelect a").on("click", function(e) {
    e.preventDefault();
    $(this).parent().hide();
    $(".event-durationSelectDiv").show();
  });

  $(".event-durationSelectDiv").hide();
}

function initDuration(){
  if($('form .duration').length > 0){
    addDurationUi();
  }

  if ( $(".event-toggleDurationSelect").length > 0 ) {
    toggleDurationSelect();
  }
}

$(document).ready(initDuration);
$(document).on('page:change', initDuration);