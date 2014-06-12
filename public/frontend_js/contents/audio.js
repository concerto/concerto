goog.provide('concerto.frontend.Content.Audio');

goog.require('concerto.frontend.Content');
goog.require('concerto.frontend.ContentTypeRegistry');
goog.require('goog.Uri');
goog.require('goog.dom');
goog.require('goog.events');
goog.require('goog.events.EventType');
goog.require('goog.style');



/**
 * Audio.
 *
 * @param {Object} data Properties for this piece of content.
 * @constructor
 * @extends {concerto.frontend.Content}
 */
concerto.frontend.Content.Audio = function(data) {
  concerto.frontend.Content.call(this, data);

  /**
   * The audio control being created.
   * @type {Object}
   */
  this.audio_control = null;

  /**
   * The URL for the audio.
   * @type {string}
   */
  this.url = data['render_details']['path'];

  /**
   * Extra parameters to include in the URL.
   * @type {?string}
   * @private
   */
  this.url_parms_ = (data['field']['config'] ? data['field']['config']['url_parms'] : null);
  if (goog.isDefAndNotNull(this.url_parms_)) {
    this.url_parms_ = this.url_parms_.trim();
    if (goog.string.startsWith(this.url_parms_, '?'))
      this.url_parms_ = goog.string.remove(this.url_parms_, '?');
    if (goog.string.startsWith(this.url_parms_, '&'))
      this.url_parms_ = goog.string.remove(this.url_parms_, '&');
    if (goog.string.contains(this.video_url, '?')) {
      this.url_parms_ = '&' + this.url_parms_;
    } else {
      this.url_parms_ = '?' + this.url_parms_;
    }
  } else {
    this.url_parms_ = '';
  }

  this.duration = 60 * 60 * 24;  // 24 hours
};
goog.inherits(concerto.frontend.Content.Audio, concerto.frontend.Content);

// Register the content type.
concerto.frontend.ContentTypeRegistry['Audio'] =
    concerto.frontend.Content.Audio;


/**
 * Build the embed iframe and signal that we're ready to use it.
 * @private
 */
concerto.frontend.Content.Audio.prototype.load_ = function() {
  this.audio_control = goog.dom.createElement('audio');
  this.audio_control.src = this.url + this.url_parms_;
  this.audio_control.autoplay = 'autoplay';
  goog.style.setSize(this.audio_control, '0', '0');
  goog.style.setSize(this.div_, '0', '0');
  goog.style.setStyle(this.audio_control, 'display', 'hidden');
  goog.style.setStyle(this.div_, 'display', 'hidden');
  goog.dom.appendChild(this.div_, this.audio_control);
  this.finishLoad();
};
