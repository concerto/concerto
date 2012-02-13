goog.require('goog.dom');
goog.require('goog.array');
goog.require('goog.style');
goog.require('concerto.frontend.position');

goog.provide('concerto.frontend.template');

concerto.frontend.Template = function(div){
  this.id = null;
  this.positions = [];
  if (!goog.isDefAndNotNull(div)){
    this.createDiv();
  } else {
    this.div_ = div;
  }
};

concerto.frontend.Template.prototype.createDiv = function(){
  var div = goog.dom.createDom('div');
  goog.style.setSize(div, '100%', '100%');
  goog.style.setStyle(div, 'background-color', 'blue');
  goog.dom.appendChild(document.body, div);
  this.div_ = div;
};

concerto.frontend.Template.prototype.load = function(data){
  this.id = data.id;
  if(goog.isDefAndNotNull(data.positions)){
    goog.array.forEach(data.positions, goog.bind(function(position_data){
      var position = new concerto.frontend.Position(this);
      position.load(position_data);
      goog.array.insert(this.positions, position);
    }, this));
  }
};

concerto.frontend.Template.prototype.getDiv = function(){ return this.div_; };
