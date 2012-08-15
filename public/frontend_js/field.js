goog.provide('concerto.frontend.Field');

goog.require('concerto.frontend.Content.ClientTime');
goog.require('concerto.frontend.Content.Graphic');
goog.require('concerto.frontend.Content.Ticker');
goog.require('concerto.frontend.Transition.Fade');
goog.require('goog.debug.Logger');
goog.require('goog.dom');
goog.require('goog.events');
goog.require('goog.events.EventTarget');
goog.require('goog.structs.Queue');



/**
 * A Position's Field.
 * Responsible for rendering the content in a position.
 *
 * @param {!concerto.frontend.Position} position The position that owns this.
 * @param {number} id The field ID number.
 * @param {string} content_path The URL to get information about the content
 *    that you would show here.
 * @param {Object=} opt_transition A transition to use between content.
 * @constructor
 * @extends {goog.events.EventTarget}
 */
concerto.frontend.Field = function(position, id, content_path, opt_transition) {
  goog.events.EventTarget.call(this);

  /**
   * Position showing this field.
   * @type {!concerto.frontend.Position}
   */
  this.position = position;

  /**
   * Field ID.
   * @type {number}
   */
  this.id = id;

  /**
   * URL for content.
   * @type {?string}
   */
  this.content_url = content_path;

  /**
   * Previous content that was shown.
   * @type {?Object}
   * @private
   */
  this.prev_content_ = null;

  /**
   * Current piece of content being shown.
   * @type {?Object}
   * @private
   */
  this.current_content_ = null;

  /**
   * Next content to show.
   * @type {goog.structs.Queue}
   * @private
   */
  this.next_contents_ = new goog.structs.Queue();

  /**
   * Should this field automatically move to the next piece of
   * content when the duration of the current content expires.
   * @type {boolean}
   * @private
   */
  this.auto_advance_ = true;

  /**
   * Transition to use between content items.
   * @type {!Object}
   * @private
   */
  this.transition_ = opt_transition || concerto.frontend.Transition.Fade;

  /**
   * Alias to the XHR connection.
   * @type {!goog.new.XhrManager}
   * @private
   */
  this.connection_ = this.position.template.screen.connection;

  this.createDiv();
  this.nextContent();
};
goog.inherits(concerto.frontend.Field, goog.events.EventTarget);


/**
 * The logger for this class.
 * @type {goog.debug.Logger}
 * @private
 */
concerto.frontend.Field.prototype.logger_ = goog.debug.Logger.getLogger(
    'concerto.frontend.Field');


/**
 * Create a div for the field.
 */
concerto.frontend.Field.prototype.createDiv = function() {
  if (!goog.isDefAndNotNull(this.div_)) {
    var properties = {'id': 'field_' + this.id, 'class': 'field'};
    var div = goog.dom.createDom('div', properties);
    this.position.inject(div);
    this.div_ = div;
  }
};


/**
 * Insert a div into the field.
 *
 * @param {Element} div The thing to insert into the field.
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
 *
 * @param {Boolean} start_load If we should trigger the startLoad event
 *    automatically.
 */
concerto.frontend.Field.prototype.loadContent = function(start_load) {
  var load_content_on_finish = start_load || null;

  this.logger_.info('Field ' + this.id + ' is looking for new content.');
  this.connection_.send(this.id, this.content_url, 'GET', '', null, 1,
      goog.bind(function(e) {

        var xhr = e.target;
        //Currently only think about the first content.
        var obj = xhr.getResponseJson()[0];
        var contents = {
          'Graphic': concerto.frontend.Content.Graphic,
          'Ticker': concerto.frontend.Content.Ticker
        };

        obj.field = {
          'size': this.position.getSize()
        };

        var next_content = new contents[obj.type](obj);
        this.next_contents_.enqueue(next_content);

        // When the content is loaded, we show it in the field,
        goog.events.listen(next_content,
            concerto.frontend.Content.EventType.FINISH_LOAD,
            this.showContent, false, this);

        // When the content has been shown for too long try to load a new one.
        goog.events.listen(next_content,
            concerto.frontend.Content.EventType.DISPLAY_END,
            this.autoAdvance, false, this);
        if (load_content_on_finish) {
          this.next_contents_.peek().startLoad();
          next_content.applyStyles(this.position.contentStyles);
        }
      }, this));
};


/**
 * Start showing the new piece of content in a field.
 * Triggered when the content has finished loading,
 * we render the content, trigger the transition, and update
 * the current field state.
 */
concerto.frontend.Field.prototype.showContent = function() {
  this.logger_.info('Field ' + this.id + ' is showing new content.');
  // Render the HTML for the div into content.div
  var content = this.next_contents_.dequeue();
  content.render();

  var transition = new this.transition_(
      this, this.current_content_, content);
  transition.go();

  this.prev_content = this.current_content_;
  this.current_content_ = content;
};


/**
 * Advance content.
 */
concerto.frontend.Field.prototype.nextContent = function() {
  this.logger_.info('Field ' + this.id +
      ' would like a new piece of content.');
  // If a piece of content is already in the queue, use that.
  if (this.next_contents_.isEmpty()) {
    this.logger_.info('Field ' + this.id + ' needs to look for more content.');
    this.loadContent(true);
  } else {
    this.next_contents_.peek().startLoad();
  }
};


/**
 * Autoadvance content.
 */
concerto.frontend.Field.prototype.autoAdvance = function() {
  if (this.auto_advance_) {
    this.logger_.info('Field ' + this.id + ' is auto-advancing.');
    this.nextContent();
  } else {
    this.logger_.info('Field ' + this.id + ' is not advancing.');
  }
};
