goog.provide('concerto.frontend.Content');
goog.provide('concerto.frontend.Content.EventType');

goog.require('goog.async.Delay');
goog.require('goog.date.DateTime');
goog.require('goog.events');
goog.require('goog.events.Event');
goog.require('goog.events.EventTarget');



/**
 * Content being shown on a screen.
 *
 * @param {Object} data Properties for this piece of content.
 * @constructor
 * @extends {goog.events.EventTarget}
 */
concerto.frontend.Content = function(data) {
  goog.events.EventTarget.call(this);

  /**
   * The Content ID.
   * @type {?number}
   */
  this.id = data.id || null;

  /**
   * The duration in seconds this content should be shown.
   * @type {number}
   */
  this.duration = data.duration || 10;
};
goog.inherits(concerto.frontend.Content, goog.events.EventTarget);


/**
 * Start loading a piece of content.
 * Construct a div for the piece of content, request the
 * timers be setup to handle the duration, and start pre-loading
 * any content necessary.
 *
 * This dispatches the START_LOAD event.
 */
concerto.frontend.Content.prototype.startLoad = function() {
  /**
   * Div to hold this content.
   * @type {Element}
   * @private
   */
  this.div_ = goog.dom.createDom('div');

  /**
   * Time this content started loading.
   * @type {goog.date.DateTime}
   * @private
   */
  this.start_ = new goog.date.DateTime();

  this.setupTimer();

  this.dispatchEvent(concerto.frontend.Content.EventType.START_LOAD);

  this.load_();
};


/**
 * Placeholder for the bulk of the loading logic.
 * You should override this function, just call finishLoad when you're
 * content is done loading into this.div_.
 *
 * @private
 */
concerto.frontend.Content.prototype.load_ = function() {
  this.finishLoad();
};


/**
 * Finish loading the content.
 *
 * This dispatches the FINISH_LOAD event.
 */
concerto.frontend.Content.prototype.finishLoad = function() {
  /**
   * The time the content finished loading.
   * @type {goog.date.DateTime}
   * @private
   */
  this.end_ = new goog.date.DateTime();

  this.dispatchEvent(concerto.frontend.Content.EventType.FINISH_LOAD);
};


/**
 * Prepare the content for rendering.
 * After this stage we can assume the content is being shown in
 * the field in some capacity.  We must stage the div in this.div.
 */
concerto.frontend.Content.prototype.render = function() {
  /**
   * A public element with the content.
   * @type {Element}
   */
  this.div = this.div_;
};


/**
 * Setup the content timer.
 * Create the content timer and set it to call the start method
 * when the COMPLETE_RENDER event is dispatched.
 */
concerto.frontend.Content.prototype.setupTimer = function() {
  var duration = this.duration * 1000;

  /**
   * A timer for the content's duration.
   * @type {goog.async.Delay}
   * @private
   */
  this.timer_ = new goog.async.Delay(this.finishTimer, duration, this);

  goog.events.listen(this,
      concerto.frontend.Content.EventType.COMPLETE_RENDER,
      this.startTimer, false, this);
};


/**
 * Start the content timer.
 */
concerto.frontend.Content.prototype.startTimer = function() {
  this.timer_.start();
};


/**
 * The content timer has finished.
 * Tell everyone that the content timer is up and they should
 * stop displaying this piece of content.
 *
 * This dispatches the DISPLAY_END event.
 */
concerto.frontend.Content.prototype.finishTimer = function() {
  this.dispatchEvent(concerto.frontend.Content.EventType.DISPLAY_END);
};


/**
 * The events fired by the content.
 *
 * @enum {string} The event types for the content.
 */
concerto.frontend.Content.EventType = {
  /**
   * Fired when a content starts loading.
   */
  START_LOAD: goog.events.getUniqueId('start_load'),

  /**
   * Fired when a content finishes loading.
   */
  FINISH_LOAD: goog.events.getUniqueId('finish_load'),

  /**
   * Fired when a piece of content starts being rendered
   * into the field.
   */
  START_RENDER: goog.events.getUniqueId('start_render'),

  /**
   * Fired when a piece of content completes rendering into
   * the field.
   */
  COMPLETE_RENDER: goog.events.getUniqueId('complete_render'),

  /**
   * Fired when a piece of content is being de-rendered.
   */
  STOP_RENDER: goog.events.getUniqueId('stop_render'),

  /**
   * Fired when a piece of content is no longer being rendered
   * anywhere on the field.
   */
  FINISH_RENDER: goog.events.getUniqueId('finish_render'),

  /**
   * Fired when a piece of content should no longer be displayed.
   */
  DISPLAY_END: goog.events.getUniqueId('display_end')
};
