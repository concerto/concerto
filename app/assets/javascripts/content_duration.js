(function(){
  var dateInput;
  var timeInput;
  
  // Date.prototype.toISOString() shim.
  if (!Date.prototype.toISOString) {
    (function() {

      function pad(number) {
        if (number < 10) {
          return '0' + number;
        }
        return number;
      }

      Date.prototype.toISOString = function() {
        return this.getUTCFullYear() +
          '-' + pad(this.getUTCMonth() + 1) +
          '-' + pad(this.getUTCDate()) +
          'T' + pad(this.getUTCHours()) +
          ':' + pad(this.getUTCMinutes()) +
          ':' + pad(this.getUTCSeconds()) +
          '.' + (this.getUTCMilliseconds() / 1000).toFixed(3).slice(2, 5) +
          'Z';
      };

    }());
  }

  var parseTimeInput = function (elementIdPrefix) {
    var date = dateInput.val();
    var time = timeInput.val();
    var timeValue = time.substring(0, time.length - 2);
    var timeAmPm = time.substring(time.length - 2, time.length);
    return new Date(date + ' ' + timeValue + ' ' + timeAmPm);
  }

  var convertTimeInput = function (elementIdPrefix) {
    var enclosingDiv = dateInput.parents('div.input');
    var isoDate = parseTimeInput(elementIdPrefix).toISOString();
    dateInput.prop('disabled', true);
    timeInput.prop('disabled', true);
    $('<input>').attr({
      type: 'hidden',
      id: elementIdPrefix,
      name: 'graphic[' + elementIdPrefix + ']',
      value: isoDate
    }).appendTo(enclosingDiv);
  }

  // Needs to be called on page load and when content type in content#new view is changed
  var initializeDateInputs = function() {
    dateInput = $('#' + elementIdPrefix + '_date');
    timeInput = $('#' + elementIdPrefix + '_time');
    convertTimeInput('start_time');
    convertTimeInput('end_time');
  }

  var bindToContentTypeSelection = function() {
    $('a:contains("/content/new?').click(initializeDateInputs);
  }

  var setupEventHandlers = function() {
    initializeDateInputs();
    bindToContentTypeSelection();
  }

  $(document).ready(setupEventHandlers);
  $(document).on('page:change', setupEventHandlers);
})();