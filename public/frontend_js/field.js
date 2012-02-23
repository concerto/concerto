goog.provide('concerto.frontend.Field');

goog.require('concerto.frontend.Content');
goog.require('goog.dom');
goog.require('goog.events');
goog.require('goog.events.EventTarget');
goog.require('goog.style');



/**
 * A Position's Field.
 * Responsible for rendering the content in a position.
 * @param {!concerto.frontend.Position} position The position that owns this.
 * @param {number} id The field ID number.
 * @constructor
 * @extends {goog.events.EventTarget}
 */
concerto.frontend.Field = function(position, id) {
  this.position = position;
  this.id = id;

  this.prev_content_ = null;
  this.current_content_ = null;
  this.next_content_ = null;

  this.createDiv();
  this.loadContent();
};
goog.inherits(concerto.frontend.Field, goog.events.EventTarget);


/**
 * Create a div for the field.
 */
concerto.frontend.Field.prototype.createDiv = function() {
  if (!goog.isDefAndNotNull(this.div_)) {
    var div = goog.dom.createDom('div');
    goog.style.setSize(div, '100%', '100%');
    this.position.inject(div);
    this.div_ = div;
  }
};


/**
 * Load a new piece of content for a field.
 * Create a new piece of content, associate it with the required events
 * and then start loading it.  Listen for the FINISH_LOAD event to
 * inidicate we should show this content and the DISPLAY_END event to
 * load a new piece of content.
 */
concerto.frontend.Field.prototype.loadContent = function() {
  var random_duration = Math.floor(Math.random() * 11);
  this.next_content_ = new concerto.frontend.Content(random_duration);

  // When the content is loaded, we show it in the field,
  goog.events.listen(this.next_content_,
      concerto.frontend.Content.EventType.FINISH_LOAD,
      this.showContent, false, this);

  // When the content has been shown for too long load a new one.
  goog.events.listen(this.next_content_,
      concerto.frontend.Content.EventType.DISPLAY_END,
      this.loadContent, false, this);

  // Actually load that piece of content.
  this.next_content_.load();
};


/**
 * Start showing the new piece of content in a field.
 * Triggered when the content has finished loading,
 * we remove the current piece of content and replace it
 * with the new one.
 *
 * This dispatches the STOP_RENDER and FINISH_RENDER events
 * for the old piece of content.
 *
 * This dispatches the COMPLETE_RENDER event for the new piece of content.
 */
concerto.frontend.Field.prototype.showContent = function() {
  // Get the HTML from the next piece of content we'll be
  // inserting into the field.
  var new_div = this.next_content_.render();

  // If there is currently content in the field, signal
  // that it should stop rendering and remove it from the dom.
  // When it is fully removed we signal it has finished rendering.
  if (goog.isDefAndNotNull(this.current_content_)) {
    this.current_content_.dispatchEvent(
        concerto.frontend.Content.EventType.STOP_RENDER);
    this.prev_content_ = this.current_content_;
    goog.dom.removeChildren(this.div_);
    this.current_content_.dispatchEvent(
        concerto.frontend.Content.EventType.FINISH_RENDER);
  }

  // Promote the new piece of content to the current piece of content.
  this.current_content_ = this.next_content_;
  this.next_content_ = null;

  // Insert the new piece of content into the field,
  // and signal it has completed rendering.
  goog.dom.appendChild(this.div_, new_div);
  this.current_content_.dispatchEvent(
      concerto.frontend.Content.EventType.COMPLETE_RENDER);
};
