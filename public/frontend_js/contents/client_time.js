goog.provide('concerto.frontend.Content.ClientTime');

goog.require('concerto.frontend.Content');
goog.require('goog.date.DateTime');
goog.require('goog.dom');
goog.require('goog.i18n.DateTimeFormat');



/**
 * The time from the client in the local format.
 *
 * @param {Object} data Properties for this piece of content.
 * @constructor
 * @extends {concerto.frontend.Content}
 */
concerto.frontend.Content.ClientTime = function(data) {
  concerto.frontend.Content.call(this, data);

  /**
   * The timezone.
   * @type {?goog.i18n.TimeZone}
   */
  this.timezone = data.timezone;
};
goog.inherits(concerto.frontend.Content.ClientTime, concerto.frontend.Content);


/**
 * Get the current time, as of now.
 * @private
 */
concerto.frontend.Content.ClientTime.prototype.load_ = function() {
  var now = new goog.date.DateTime();
  var date_printer = new goog.i18n.DateTimeFormat(
      goog.i18n.DateTimeFormat.Format.MEDIUM_DATE);
  var time_printer = new goog.i18n.DateTimeFormat(
      goog.i18n.DateTimeFormat.Format.SHORT_TIME);
  var pretty_time = date_printer.format(now, this.timezone) +
      ' ' + time_printer.format(now, this.timezone);
  goog.dom.setTextContent(this.div_, pretty_time);
  this.finishLoad();
};
