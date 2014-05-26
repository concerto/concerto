function addUserSelectUi() {
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
  $('.user_filter').on('input', function() {
    $(this).listFilter();
  });
}

function addUser(name, user_id, group_id) {
  $('#select-users-btn').text(name);
  $('#selectedUser').attr('data-user-id', user_id);
  $('#membership_user_id').val(user_id);
  $('#membership_group_id').val(group_id);
}

function initUserSelect() {
  if($('.dd-select-users').length > 0) {
    addUserSelectUi();
  }
}

$(document).ready(initUserSelect);
$(document).on('page:change', initUserSelect);