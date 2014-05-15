goog.provide('concerto.frontend.Content.ClientTime');

goog.require('concerto.frontend.Content');
goog.require('concerto.frontend.ContentTypeRegistry');
goog.require('concerto.frontend.Helpers');
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
   * Should the font size be automatically adjusted to optimize
   * display within the field?
   * @type {boolean}
   */
  this.autosize_font = (data['field']['config'] ?
                        data['field']['config']['autosize_text'] : false);

  /**
   * The height of the field the time is being shown in.
   * @type {number}
   * @private
   */
  this.field_height_ = data['field']['size']['height'];

  /**
   * The width of the field the time is being shown in.
   * @type {number}
   * @private
   */
  this.field_width_ = data['field']['size']['width'];

  /**
   * The timezone.
   * @type {?goog.i18n.TimeZone}
   */
  this.timezone = data['timezone'];

  /**
   * The datetime format.
   * @type {?string}
   * @private
   */
  this.format_ = (data['field']['config'] ?
                  data['field']['config']['time_format'] : null);
};
goog.inherits(concerto.frontend.Content.ClientTime, concerto.frontend.Content);

// Register the content type.
concerto.frontend.ContentTypeRegistry['ClientTime'] =
    concerto.frontend.Content.ClientTime;


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

  if (this.format_ != null && this.format_.trim() != '') {
    pretty_time = new goog.i18n.DateTimeFormat(this.format_).format(
        now, this.timezone);
  }

  goog.dom.setTextContent(this.div_, pretty_time);
  this.finishLoad();
};
