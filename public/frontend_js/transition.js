goog.provide('concerto.frontend.Transition');

goog.require('concerto.frontend.Content.EventType');
goog.require('goog.dom');
goog.require('goog.events');
goog.require('goog.events.EventTarget');



/**
 * A Transition between contents.
 * Responsble for swapping what is in the field.
 *
 * @param {concerto.frontend.Field} field The field holding the content.
 * @param {concerto.frontend.Content} current The current content shown.
 * @param {concerto.frontend.Content} next The next content to show.
 * @constructor
 * @extends {goog.events.EventTarget}
 */
concerto.frontend.Transition = function(field, current, next) {
  goog.events.EventTarget.call(this);

  /**
   * Field requsting the transition.
   * @type {!concerto.frontend.Field}
   */
  this.field = field;

  /**
   * Curent piece of content to be transitioned away.
   * @type {?concerto.frontend.Content}
   * @private
   */
  this.current_content_ = current || null;

  /**
   * New piece of content to transition in.
   * @type {?concerto.frontend.Content}
   * @private
   */
  this.next_content_ = next || null;
};
goog.inherits(concerto.frontend.Transition, goog.events.EventTarget);


/**
 * Trigger the switch.
 * If there is content to remove, we fade that out and then fade in
 * the new stuff (if there is any).  Otherwise we just move in the
 * new content.
 */
concerto.frontend.Transition.prototype.go = function() {
  if (goog.isDefAndNotNull(this.current_content_)) {
    this.out_();
  } else if (goog.isDefAndNotNull(this.next_content_)) {
    this.in_();
  }
};


/**
 * Start removing the current content and then call {@link outDone_} to
 * finish it up.
 *
 * This dispatches the STOP_RENDER event.
 * @private
 */
concerto.frontend.Transition.prototype.out_ = function() {
  this.current_content_.dispatchEvent(
      concerto.frontend.Content.EventType.STOP_RENDER);
  this.outDone_();
};


/**
 * Finish removing the current content.
 * Removes the div from the screen completely.
 *
 * This dispatches the FINISH_RENDER event.
 * @private
 */
concerto.frontend.Transition.prototype.outDone_ = function() {
  goog.dom.removeNode(this.current_content_.div);
  this.current_content_.dispatchEvent(
      concerto.frontend.Content.EventType.FINISH_RENDER);

  if (goog.isDefAndNotNull(this.next_content_)) {
    this.in_();
  }
};


/**
 * Add the new content to the field, call {@link inDone_} when we finish.
 *
 * This dispatches the START_RENDER event.
 * @private
 */
concerto.frontend.Transition.prototype.in_ = function() {
  this.next_content_.dispatchEvent(
      concerto.frontend.Content.EventType.START_RENDER);

  this.field.inject(this.next_content_, this.next_content_.autosize_font);
  this.inDone_();
};


/**
 * Finished fading in the new content.
 *
 * This dispatches the COMPLETE_RENDER event.
 * @private
 */
concerto.frontend.Transition.prototype.inDone_ = function() {
  this.next_content_.dispatchEvent(
      concerto.frontend.Content.EventType.COMPLETE_RENDER);
};
