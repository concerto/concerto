function addUserSelectUi() {
  // Create UI for user selection and filtering
  $('.dropdown-control.dd-select-users').each(function() {
    $(this).qtip( {
      id: 'select-users',
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
              api.set('content.text', $('#select-users').html() );
            }

            initUserSelectState();

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

function initUserSelectState() {
  // Filter user list by search input
  $('.user_filter').on('input', function() {
    $(this).listFilter();
  });
}

function addUser(name, user_id) {
  // Show name of selected user
  $('#select-users-btn').text(name);

  // Check which type of page we are on
  //  determines which form field we set
  //   the user id for
  if ($('#membership_user_id').length) {
    // Submit membership user id
    $('#membership_user_id').val(user_id);
  } else if ($('#group_new_leader').length) {
    // Submit group leader id
    $('#group_new_leader').val(user_id);
  }
}

function initUserSelect() {
  if($('.dd-select-users').length > 0) {
    addUserSelectUi();
  }
}

$(document).ready(initUserSelect);
$(document).on('page:change', initUserSelect);