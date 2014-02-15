goog.provide('concerto.frontend.Content.EmergencyAlert');

goog.require('concerto.frontend.Content');
goog.require('concerto.frontend.ContentTypeRegistry');
goog.require('goog.Uri');
goog.require('goog.dom');
goog.require('goog.events');
goog.require('goog.events.EventType');
goog.require('goog.style');


/**
 * EmergencyAlerts.
 *
 * @param {Object} data Properties for this piece of content.
 * @constructor
 * @extends {concerto.frontend.Content}
 */
concerto.frontend.Content.EmergencyAlert = function(data) {
  concerto.frontend.Content.call(this, data);

  /**
   * The height of the field the alert message is being shown in.
   * @type {number}
   * @private
   */
  this.field_height_ = data.field.size.height;

  /**
   * The width of the field the alert message is being shown in.
   * @type {number}
   * @private
   */
  this.field_width_ = data.field.size.width;

  /**
   * The alert message being displayed.
   * @type {Object}
   */
  this.alert = data['render_details']['alert'];

};
goog.inherits(concerto.frontend.Content.EmergencyAlert, concerto.frontend.Content);

concerto.frontend.ContentTypeRegistry['EmergencyAlert'] = concerto.frontend.Content.EmergencyAlert;

/**
 * Load the text.
 * @private
 */
concerto.frontend.Content.EmergencyAlert.prototype.load_ = function() {

  console.log('Loading Emergency Alert ... ');

  goog.dom.removeChildren(this.div_);
  var alert_fragment = goog.dom.htmlToDocumentFragment('<div style="background-color: red;">' + this.alert + '</div>');
  goog.dom.appendChild(this.div_, alert_fragment);

  this.div_ = concerto.frontend.Helpers.Autofit(this.div_, this.field_width_, 
                                                this.field_height_); 
  
  this.finishLoad();

};