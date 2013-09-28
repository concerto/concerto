function addSubscriptionsUi(){
  var title = $('#add-sub-btn').attr('title')
  $('#add-sub-btn').qtip( {
      id: 'add-sub',
      content: {
        title: {
          text: title,
          button: true
        }
      },
      position: {
        at: 'bottom center', // Position the tooltip above the link
        my: 'top left',
        viewport: $(window) // Keep the tooltip on-screen at all times
      },
      events: {
        // this is used to highlight the first input in the box when it is shown...
        show: function(event, api) {
          setTimeout(function() {
            
            // Update the content of the tooltip on each show
            var target = $(event.originalEvent.target);
            
            $('.qtip-content input:first').focus(); }, 50);
          }
      },
      show: {
        event: 'click', // Show it on click...
        solo: true // ...and hide all other tooltips...
      },
      hide: 'unfocus',
      style: 'qtip-light qtip-shadow qtip-rounded qtip-nopadding qtip-minheight'
    });

  initializeFrequencySliders();

  if ($("#count_field_configs").val() <= 0) {
    toggleFieldConfigsCont();
  } else {
    $(".event-toggleFieldConfigsDiv").parent().hide();
  }
}

function toggleFieldConfigsCont() {
  $(".event-fieldConfigsDiv").hide();

  $(".event-toggleFieldConfigsDiv").on("click", function(e) {
    e.preventDefault();
    $(this).parent().hide();
    $(".event-fieldConfigsDiv").show();
  });

  $(".event-fieldConfigsDiv").hide();
}

function showSaveSubsAlert() {
  $("#save-subscriptions-alert")
    .removeClass("alert-zero")
    .addClass("alert-info")
    .find("input")
      .addClass("btn-primary")
      .attr("disabled", false)
      .end()
    .find(".save-msg")
      .html("<b>You have made changes to the subscriptions or configuration for this field.</b><br />Please click this button to commit your changes, or exit this page to cancel.");
}

function initializeFrequencySliders() {
  $(".frequency").each(function() {
    var frequency_elem = $(this).find(".frequency_range");
    
    $(frequency_elem).rangeinput({
      css: {
        handle: 'handle thin'
      }
    }).hide();

    // Manually propogate the new value down to the core input.
    // This allows our AJAX to automatically do it's thing.
    var range_elem = $(this).find(":range");
    var api = $(range_elem).data("rangeinput");
    api.change(function(evt, value) {
      range_elem.val(value);
      range_elem.trigger('change');
    });

    var handle_elem = $(this).find(".handle");
    $(handle_elem).html('&nbsp;');
    
  });
}

function remove_field_config_fields (link) {
  $(link).prev("input[type=hidden]").val("1");
  $(link).closest(".field-config-fields").hide();
  showSaveSubsAlert();
}

function add_field_config_fields (link, association, content) {
  var new_id = new Date().getTime();
  var regexp = new RegExp("new_" + association, "g");
  $(link).parent().find('.field-configs').first().append(content.replace(regexp, new_id));
  showSaveSubsAlert();
}

function remove_subscription_handler() {
  $('#subscriptions-list tbody').on('ajax:success', '.btnRemoveSubscription', function(){
    $(this).parents("tbody").append("<tr><td></td></tr>");
    $(this).parents("tr").remove();
  });
}


function initSubscriptions() {
  if($('.dd-add-sub').length > 0){
    addSubscriptionsUi();
    $("#new_subscription").formSavior();
  }
  if($('.btnRemoveSubscription').length > 0){
    remove_subscription_handler();
  }
}

$(document).ready(initSubscriptions);
$(document).on('page:change', initSubscriptions);
