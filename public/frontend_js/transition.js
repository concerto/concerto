goog.provide('concerto.frontend.field.Transition');

goog.require('concerto.frontend.Content.EventType');
goog.require('goog.events');
goog.require('goog.events.EventTarget');
goog.require('goog.fx.dom.FadeInAndShow');
goog.require('goog.fx.dom.FadeOutAndHide');



/**
 * A Transition between contents.
 * Responsble for swapping what is in the field.
 * @param {concerto.frontend.Field} field The field holding the content.
 * @param {concerto.frontend.Content} current The current content shown.
 * @param {concerto.frontend.Content} next The next content to show.
 * @constructor
 * @extends {goog.events.EventTarget}
 */
concerto.frontend.field.Transition = function(field, current, next) {
  this.field = field;
  this.current_content_ = current || null;
  this.next_content_ = next || null;

  this.duration = 1000;
};
goog.inherits(concerto.frontend.field.Transition, goog.events.EventTarget);


/**
 * Trigger the switch.
 * If there is content to remove, we fade that out and then fade in
 * the new stuff (if there is any).  Otherwise we just fade in the
 * new content.
 */
concerto.frontend.field.Transition.prototype.go = function() {
  if (goog.isDefAndNotNull(this.current_content_)) {
    this.out_();
  } else if (goog.isDefAndNotNull(this.next_content_)) {
    this.in_();
  }
};


/**
 * Fade out the current content.
 *
 * This dispatches the STOP_RENDER event.
 * @private
 */
concerto.frontend.field.Transition.prototype.out_ = function() {
  this.current_content_.dispatchEvent(
      concerto.frontend.Content.EventType.STOP_RENDER);
  var animOut = new goog.fx.dom.FadeOutAndHide(this.current_content_.div,
      this.duration);
  goog.events.listen(animOut, goog.fx.Animation.EventType.END,
      this.outDone_, false, this);
  animOut.play();
};


/**
 * Finished fading out current content.
 * Removes the div from the screen completely.
 *
 * This dispatches the FINISH_RENDER event.
 * @private
 */
concerto.frontend.field.Transition.prototype.outDone_ = function() {
  goog.dom.removeNode(this.current_content_.div);
  this.current_content_.dispatchEvent(
      concerto.frontend.Content.EventType.FINISH_RENDER);

  if (goog.isDefAndNotNull(this.next_content_)) {
    this.in_();
  }
};


/**
 * Fade in the new content.
 *
 * This dispatches the START_RENDER event.
 * @private();
 */
concerto.frontend.field.Transition.prototype.in_ = function() {
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


/**
 * Finished fading in the new content.
 *
 * This dispatches the COMPLETE_RENDER event.
 * @private
 */
concerto.frontend.field.Transition.prototype.inDone_ = function() {
  this.next_content_.dispatchEvent(
      concerto.frontend.Content.EventType.COMPLETE_RENDER);
};
