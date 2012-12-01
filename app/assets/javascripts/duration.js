function addDurationUi() {
  $(".duration_range").rangeinput();
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
  $(".duration_range").hide();
}

function initDuration(){
  if($('.duration').length > 0){
    addDurationUi();
  }
}

$(document).ready(initDuration);
