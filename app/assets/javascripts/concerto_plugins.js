function toggleFields()
{
    var source = $('select#concerto_plugin_source').val();
    var url_field = $('input#concerto_plugin_source_url');
    var name_box = $('input#concerto_plugin_gem_name');
    var name_select = $('select#gem_name_select');
    if (url_field.length > 0) {
        if (source == 'rubygems') {
            $(url_field).closest('div.clearfix').hide();
            $(name_select).closest('div.clearfix').hide();
            $(name_select).prop('disabled', true);
            $(name_box).closest('div.clearfix').show();
            $(name_box).focus();
        }
        else if (source == 'concerto_plugins') {
            $(name_box).closest('div.clearfix').hide();
            $(url_field).closest('div.clearfix').hide();
            $(name_select).closest('div.clearfix').show();
            $(name_select).prop('disabled', false);
            $(name_select).focus();
        }
        else {
            if (source == 'git') {
                $(url_field).attr('placeholder', 'https://foo.bar/baz/repo.git');
            } else if (source == 'path') {
                $(url_field).attr('placeholder', '/path/to/extracted/gem');
            }
            $(name_select).closest('div.clearfix').hide();
            $(name_select).prop('disabled', true);
            $(url_field).closest('div.clearfix').show();
            $(name_box).closest('div.clearfix').show();
            $(name_box).focus();
        }
    }
}

function bindListeners() {
  // hookup the listener to toggle placeholder text and visibility of source url
  $('select#concerto_plugin_source').change(toggleFields);
  // since the default source is rubygems, hide the source url on load
  $('select#concerto_plugin_source').trigger('change');

  $('a.update-plugin-btn').on('ajax:beforeSend', updatePluginBeforeSend);
  $('a.update-plugin-btn').on('ajax:success', updatePluginSuccess);
  $('a.update-plugin-btn').on('ajax:error', updatePluginError);
}

function updatePluginBeforeSend(e, data, status, xhr) {
  $('#updatePluginResults').html('<span class="fa fa-spinner fa-spin"></span> Updating...');
}

function updatePluginError(e, data, status, xhr) {
  $('#updatePluginResults').html('<div class="alert alert-warning">Unable to update plugin.</br><pre>' + status + '</pre></div>');
}

function updatePluginSuccess(e, data, status, xhr) {
  var msg = '';
  if (!data['bundle_success'] || !data['rake_success']) {
    msg = '<div class="alert alert-warning">Unable to update plugin.</br><pre>' + data['bundle_output'] + '</pre><br/>';
    if (data['rake_output'] != null) {
      msg = msg + '<pre>' + data['rake_output'] + '</pre><br/>';
    }
    msg = msg + '</div>';
    $('#updatePluginResults').html(msg);
  } else {
    window.location.replace(data['redirect_to']);
  }
}

$(document).ready(bindListeners);
$(document).on('page:change', bindListeners);
