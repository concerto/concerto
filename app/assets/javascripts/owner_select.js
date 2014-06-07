function addOwnerSelectUi() {
  // Create UI for user selection and filtering
  $('.dropdown-control.dd-select-owner').each(function() {
    $(this).qtip( {
      id: 'select-owner',
      content: {
        title: {
          text: $(this).attr('title'),
          button: true
        }
      },
      position: {
        my: 'top left',
        at: 'bottom right',
        viewport: $(window)
      },
      events: {
        show: function(event, api) {
          setTimeout(function() {

            var target = $(event.originalEvent.target);

            if(target.length) {
              api.set('content.text', $('#select-owner').html() );
            }

            initOwnerSelectState();

            $('.qtip-content input:first').focus(); }, 50);
          }
      },
      show: {
        event: 'click',
        solo: true
      },
      hide: 'unfocus',
      style: 'qtip-light qtip-shadow qtip-fixedwidth-medium qtip-rounded qtip-nopadding'
    });
  }).click(function(e) {
    e.preventDefault();
  });
}

function initOwnerSelectState() {
  // Filter user list by search input
  $('.owner_filter').on('input', function() {
    $(this).listFilter();
  });
}

function addOwner(name, type, owner_id) {
  // Show name of selected user
  $('#select-owner-btn').text(name);

  if (type == "user_select") {
    // Check which type of page we are on
    //  determines which form field we set
    //   the user id for
    if ($('#membership_user_id').length) {
      // Submit membership user id
      $('#membership_user_id').val(owner_id);
    } else if ($('#group_new_leader').length) {
      // Submit group leader id
      $('#group_new_leader').val(owner_id);
    } else if ($('#screen_owner_type').length && $('#screen_owner_id').length) {
      $('#screen_owner_type').val(owner_id.split("-")[0]);
      $('#screen_owner_id').val(owner_id.split("-")[1]);
    }
  } 
  else if (type == "group_select") {
    if ($('#screen_owner_type').length && $('#screen_owner_id').length) {
      $('#screen_owner_type').val(owner_id.split("-")[0]);
      $('#screen_owner_id').val(owner_id.split("-")[1]);
    }
  }
}

function initOwnerSelect() {
  if($('.dd-select-owner').length > 0) {
    addOwnerSelectUi();
  }
}

$(document).ready(initOwnerSelect);
$(document).on('page:change', initOwnerSelect);