goog.provide('concerto.frontend.Transition.Slide');

goog.require('concerto.frontend.Content.EventType');
goog.require('concerto.frontend.Transition');
goog.require('goog.debug.Logger');
goog.require('goog.events');
goog.require('goog.fx');
goog.require('goog.fx.Animation.EventType');
goog.require('goog.fx.dom.Slide');



/**
 * Extends {@link concerto.frontend.Transition} by providing a
 * fade out then fade in style transition.
 *
 * @param {concerto.frontend.Field} field The field holding the content.
 * @param {concerto.frontend.Content=} opt_current The current content shown.
 * @param {concerto.frontend.Content=} opt_next The next content to show.
 * @constructor
 * @extends {concerto.frontend.Transition}
 */
concerto.frontend.Transition.Slide = function(field, opt_current, opt_next) {
  /**
   * Slide duration.
   * @type {number}
   */
  this.duration = 500;

  concerto.frontend.Transition.call(this, field, opt_current, opt_next);
};
goog.inherits(concerto.frontend.Transition.Slide, concerto.frontend.Transition);


/**
 * The logger for this class.
 * @type {goog.debug.Logger}
 * @private
 */
concerto.frontend.Transition.Slide.prototype.logger_ =
    goog.debug.Logger.getLogger('concerto.frontend.Transition.Slide');


/**
 * Slide out the current content and call {@link outDone_} when
 * the slide has completed.
 *
 * This dispatches the STOP_RENDER event.
 * @private
 */
concerto.frontend.Transition.Slide.prototype.out_ = function() {
  this.current_content_.dispatchEvent(
      concerto.frontend.Content.EventType.STOP_RENDER);
  var animOut = new goog.fx.dom.Slide(this.current_content_.div,
      [this.current_content_.div.offsetLeft,
        this.current_content_.div.offsetTop],
      [0 - this.field.position.div_.clientWidth,
        this.current_content_.div.offsetTop],
      this.duration, goog.fx.easing.easeIn);
  goog.events.listen(animOut, goog.fx.Animation.EventType.END,
      this.outDone_, false, this);
  animOut.play();
};


/**
 * Slide in the new content and call {@link inDone_} when
 * the slide has completed.
 *
 * This dispatches the START_RENDER event.
 * @private
 */
concerto.frontend.Transition.Slide.prototype.in_ = function() {
  this.logger_.info('Field ' + this.field.id + ' is sliding in.');

  this.next_content_.dispatchEvent(
      concerto.frontend.Content.EventType.START_RENDER);

  //this.next_content_.div.style.display = 'none';
  this.field.inject(this.next_content_.div);

  var animIn = new goog.fx.dom.Slide(this.next_content_.div,
      [this.field.position.div_.clientWidth, 0],
      [0, 0],
      this.duration, goog.fx.easing.easeOut);
  goog.events.listen(animIn, goog.fx.Animation.EventType.END,
      this.inDone_, false, this);
  animIn.play();
};
