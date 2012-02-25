goog.provide('concerto.frontend.Transition.Fade');

goog.require('concerto.frontend.Content.EventType');
goog.require('concerto.frontend.Transition');
goog.require('goog.events');
goog.require('goog.events.EventTarget');
goog.require('goog.fx.dom.FadeInAndShow');
goog.require('goog.fx.dom.FadeOutAndHide');



/**
 * Extends {@link concerto.frontend.Transition} by providing a
 * fade out then fade in style transition.
 * @param {concerto.frontend.Field} field The field holding the content.
 * @param {concerto.frontend.Content=} opt_current The current content shown.
 * @param {concerto.frontend.Content=} opt_next The next content to show.
 * @constructor
 * @extends {concerto.frontend.Transition}
 */
concerto.frontend.Transition.Fade = function(field, opt_current, opt_next) {
  this.duration = 500;

  concerto.frontend.Transition.call(this, field, opt_current, opt_next);
};
goog.inherits(concerto.frontend.Transition.Fade, concerto.frontend.Transition);


/**
 * Fade out the current content and call {@link outDone_} when
 * the fade has completed.
 *
 * This dispatches the STOP_RENDER event.
 * @private
 */
concerto.frontend.Transition.Fade.prototype.out_ = function() {
  this.current_content_.dispatchEvent(
      concerto.frontend.Content.EventType.STOP_RENDER);
  var animOut = new goog.fx.dom.FadeOutAndHide(this.current_content_.div,
      this.duration);
  goog.events.listen(animOut, goog.fx.Animation.EventType.END,
      this.outDone_, false, this);
  animOut.play();
};


/**
 * Fade in the new content and call {@link inDone_} when
 * the fade has completed.
 *
 * This dispatches the START_RENDER event.
 * @private
 */
concerto.frontend.Transition.Fade.prototype.in_ = function() {
  this.next_content_.dispatchEvent(
      concerto.frontend.Content.EventType.START_RENDER);

  this.next_content_.div.style.display = 'none';
  this.field.inject(this.next_content_.div);

  var animIn = new goog.fx.dom.FadeInAndShow(this.next_content_.div,
      this.duration);
  goog.events.listen(animIn, goog.fx.Animation.EventType.END,
      this.inDone_, false, this);
  animIn.play();
};
