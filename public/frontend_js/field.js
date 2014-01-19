goog.provide('concerto.frontend.Field');

goog.require('concerto.frontend.ContentTypeRegistry');
goog.require('concerto.frontend.ContentTypes');
goog.require('goog.array');
goog.require('goog.debug.Logger');
goog.require('goog.dom');
goog.require('goog.events');
goog.require('goog.events.EventTarget');
goog.require('goog.math');
goog.require('goog.structs.Queue');



/**
 * A Position's Field.
 * Responsible for rendering the content in a position.
 *
 * @param {!concerto.frontend.Position} position The position that owns this.
 * @param {number} id The field ID number.
 * @param {string} name The field name.
 * @param {string} content_path The URL to get information about the content
 *    that you would show here.
 * @param {Object=} opt_transition A transition to use between content.
 * @param {Object=} opt_config Field configuration to pass on to the content.
 * @constructor
 * @extends {goog.events.EventTarget}
 */
concerto.frontend.Field = function(position, id, name, content_path,
                                   opt_transition, opt_config) {
  goog.events.EventTarget.call(this);

  if (goog.DEBUG) {
    if (goog.isDefAndNotNull(opt_config)) {
      for (var prop in opt_config) {
        if (opt_config.hasOwnProperty(prop)) {
          this.logger_.info('Field ' + id + ' has configuration ' +
              prop + ': ' + opt_config[prop]);
        }
      }
    }
  }

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
   * Field Name.
   * @type {string}
   */
  this.name = name;

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
  this.transition_ = opt_transition;

  /**
   * Configuration properties for the field
   * @type {!Object}
   * @private
   */
  this.config_ = opt_config;

  /**
   * Alias to the XHR connection.
   * @type {!goog.net.XhrManager}
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
    goog.style.setSize(div, '100%', '100%');
    this.position.inject(div);
    this.div_ = div;
  }
};


/**
 * Insert a div into the field.
 *
 * @param {Element} div The thing to insert into the field.
 */
concerto.frontend.Field.prototype.inject = function(div, autosize_font) {
  goog.dom.appendChild(this.div_, div);

  if (goog.isDefAndNotNull(autosize_font) && autosize_font == true) {
    //console.log("injected content size is " + goog.style.getSize(div));
    concerto.frontend.Helpers.SizeToFit(div, this.div_);
    //console.log("adjusted content size is " + goog.style.getSize(div));
  }
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

  // if the position is no longer valid (like when a template changes) then abort
  if (this.position == null) {
    return;
  }

  /**
   * HACK HACK HACK
   * Sideload ClientTime content for 'Time' fields.
   * Remove when FieldConfig is implemented.
   */
  if (this.name == 'Time') {
    var options = {
      'duration': 15,
      'id': 0,
      'name': 'System Time',
      'type': 'ClientTime',
      'render_details': {'data': null},
      'field': {'size': this.position.getSize(), 'config' : this.config_}
    };
    var clock_klass = concerto.frontend.ContentTypeRegistry['ClientTime'];
    var clock = new clock_klass(options);
    this.next_contents_.enqueue(clock);
    goog.events.listenOnce(clock,
        concerto.frontend.Content.EventType.FINISH_LOAD,
        this.showContent, false, this);
    goog.events.listenOnce(clock,
        concerto.frontend.Content.EventType.DISPLAY_END,
        this.autoAdvance, false, this);
    this.next_contents_.peek().startLoad();
    return;
  }
  /** END HACK HACK HACK */

  var params = this.position.template.screen.getQueryData();
  var url = this.content_url + '?' + params.toString();
  this.connection_.send('field' + this.id, url, 'GET', '', null, 1,
      goog.bind(function(e) {

        var xhr = e.target;

        if (!xhr.isSuccess()) {
          // Error fetching content.
          this.logger_.warning('Field ' + this.id +
              ' was unable to fetch content. ' + xhr.getLastError());
          return setTimeout(
              goog.bind(function() {this.nextContent(true)}, this), 10);
        }

        var template_id = xhr.getResponseHeader('X-Concerto-Template-ID');
        var contents_data = xhr.getResponseJson();

        if (goog.isDefAndNotNull(template_id)) {
          // if the template id that is in the header does not match the template
          // id currently used by the screen, then tell the screen to refresh.
          if (this.position.template.id != parseInt(template_id)) {
            return this.position.template.screen.refresh();
          }
        }

        if (!contents_data.length) {
          // No content for this field.
          this.logger_.info('Field ' + this.id + ' received empty content.');
          return setTimeout(
              goog.bind(function() {this.nextContent(true)}, this), 10);
        }

        goog.array.forEach(contents_data, goog.bind(function(content_data) {
          // Slip in some data about the field.  Content might want to know the
          // current size of the position it is being rendered in.
          content_data.field = {
            'size': this.position.getSize(),
            'config': this.config_
          };
          if (content_data['type'] in concerto.frontend.ContentTypeRegistry) {
            var content = new concerto.frontend.ContentTypeRegistry[
                    content_data['type']](content_data);
            this.next_contents_.enqueue(content);

            this.logger_.info('Field ' + this.id + ' queued ' +
                content_data['type'] + ' content ' + content_data['id']);

            // When the content is loaded, we show it in the field,
            goog.events.listenOnce(content,
                concerto.frontend.Content.EventType.FINISH_LOAD,
                this.showContent, false, this);

            // When the content has been shown for too long
            // try to load a new one.
            goog.events.listenOnce(content,
                concerto.frontend.Content.EventType.DISPLAY_END,
                this.autoAdvance, false, this);
          } else {
            this.logger_.warning('Field ' + this.id +
                ' Unable to find ' + content_data['type'] +
                ' renderer for content ' + content_data['id']);
          }
        }, this));
        if (load_content_on_finish && !this.next_contents_.isEmpty()) {
          this.next_contents_.peek().startLoad();
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
  content.applyStyles(this.position.getContentStyles());
  content.render();

  var transition = new this.transition_(
      this, this.current_content_, content);
  transition.go();

  goog.events.removeAll(this.prev_content);
  if (this.prev_content) {
    this.prev_content.dispose();
  }
  this.prev_content = null;

  this.prev_content = this.current_content_;
  this.current_content_ = content;
};


/**
 * Advance content.
 *
 * @param {Boolean} in_error_state If the frontend is having trouble
 *    fetching content we might act differently.
 */
concerto.frontend.Field.prototype.nextContent = function(in_error_state) {
  in_error_state = in_error_state || false;
  this.logger_.info('Field ' + this.id + ' would like a new piece of content' +
      ' (error state: ' + in_error_state + ' ).');
  // If a piece of content is already in the queue, use that.
  if (this.next_contents_.isEmpty()) {
    this.logger_.info('Field ' + this.id +
        ' needs to look for more content [queue is empty].');
    if (in_error_state) {
      var delay = concerto.frontend.Field.ERROR_DELAY;
      this.logger_.info('In error state, sleeping for ' + delay + ' seconds.');
      setTimeout(
          goog.bind(function() {this.loadContent(true);}, this), delay * 1000);
    } else {
      this.loadContent(true);
    }
  } else {
    this.logger_.info('Field ' + this.id +
        ' is getting content from its queue.');
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


/**
 * Delay between retries.
 *
 * If there is no content or the backend is NOK we randomize our delays
 * to try and distribute the spikes slightly.
 *
 * @return {Number} Number of seconds to delay.
 */
concerto.frontend.Field.ERROR_DELAY = goog.math.uniformRandom(10, 60);
