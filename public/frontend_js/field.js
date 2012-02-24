goog.provide('concerto.frontend.Field');

goog.require('concerto.frontend.Content');
goog.require('concerto.frontend.field.Transition');
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

  this.auto_advance_ = true;

  this.createDiv();
  this.nextContent();
};
goog.inherits(concerto.frontend.Field, goog.events.EventTarget);


/**
 * Create a div for the field.
 */
concerto.frontend.Field.prototype.createDiv = function() {
  if (!goog.isDefAndNotNull(this.div_)) {
    var properties = {'id': 'field_' + this.id, 'class': 'field'};
    var div = goog.dom.createDom('div', properties);
    goog.style.setSize(div, '100%', '100%');
    this.position.inject(div);
    this.div_ = div;
  }
};


/**
 * Inset a div into the field.
 * @param {!Object} div The thing to insert into the field.
 */
concerto.frontend.Field.prototype.inject = function(div) {
  goog.dom.appendChild(this.div_, div);
};


/**
 * Get and setup the next content for a field.
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

  // When the content has been shown for too long try to load a new one.
  goog.events.listen(this.next_content_,
      concerto.frontend.Content.EventType.DISPLAY_END,
      this.autoAdvance, false, this);
};


/**
 * Start showing the new piece of content in a field.
 * Triggered when the content has finished loading,
 * we render the content, trigger the transition, and update
 * the current field state.
 */
concerto.frontend.Field.prototype.showContent = function() {
  // Render the HTML for the div into content.div
  this.next_content_.render();

  var transition = new concerto.frontend.field.Transition(
      this, this.current_content_, this.next_content_);
  transition.go();

  // Promote the new piece of content to the current piece of content.
  this.current_content_ = this.next_content_;
  this.next_content_ = null;
};


/**
 * Advance content.
 */
concerto.frontend.Field.prototype.nextContent = function() {
  // If a piece of content is already in the queue, use that.
  if (!goog.isDefAndNotNull(this.next_content_)) {
    this.loadContent();
  }
  this.next_content_.load();
};


/**
 * Autoadvance content.
 */
concerto.frontend.Field.prototype.autoAdvance = function() {
  if (this.auto_advance_) {
    this.nextContent();
  }
};
