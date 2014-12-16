(function(){
  var startPrefix = 'start_time';
  var endPrefix = 'end_time';
  var startDateInput;
  var startTimeInput;
  var endDateInput;
  var endTimeInput;
  
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

  var parseDurationInput = function (dateInput, timeInput) {
    var date = dateInput.val();
    var time = timeInput.val();
    var timeValue = time.substring(0, time.length - 2);
    var timeAmPm = time.substring(time.length - 2, time.length);
    return new Date(date + ' ' + timeValue + ' ' + timeAmPm);
  }

  var convertDurationInput = function (dateInput, timeInput, idPrefix) {
    var enclosingDiv = dateInput.parents('div.input');
    var isoDate = parseDurationInput(dateInput, timeInput).toISOString();
    dateInput.prop('disabled', true);
    timeInput.prop('disabled', true);
    $('<input>').attr({
      type: 'hidden',
      id: idPrefix,
      name: 'graphic[' + idPrefix + ']',
      value: isoDate
    }).appendTo(enclosingDiv);
  }

  // Needs to be called on page load and when content type in content#new view is changed
  var initializeDateInputs = function() {
    startDateInput = $('#' + startPrefix + '_date');
    startTimeInput = $('#' + startPrefix + '_time');
    endDateInput = $('#' + endPrefix + '_date');
    endTimeInput = $('#' + endPrefix + '_time');
    convertDurationInput(startDateInput, startTimeInput, startPrefix);
    convertDurationInput(endDateInput, endTimeInput, endPrefix);
  }

  var bindToForm = function() {
    $('form[action="/content"]').submit(initializeDateInputs);
  }

  var bindToContentTypeSelection = function() {
    $("a[href*='/content/new?']").click(bindToForm);
  }

  var setupEventHandlers = function() {
    bindToForm();
    bindToContentTypeSelection();
  }

  $(document).ready(setupEventHandlers);
  $(document).on('page:change', setupEventHandlers);
})();