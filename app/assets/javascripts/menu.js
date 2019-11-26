
function switch_nav(){
  if (typeof(localStorage) !== "undefined") {
    if(localStorage.getItem("nav")) {
      localStorage.removeItem("nav");
    } else {
      localStorage.setItem("nav", 'true');
    }
  }
}

function update(animate) {
  var nav = $("nav");
  if (typeof(localStorage) !== "undefined") {
    if(localStorage.getItem("nav")) {
    nav.addClass("minimized");
    nav.removeClass("no-animation");
    if(!animate) {
      nav.addClass("no-animation");
    }
  } else {
    nav.removeClass("minimized");
    nav.removeClass("no-animation");
    if(!animate) {
      nav.addClass("no-animation");
    }
  }
}
}

function menuCollapse() {
  switch_nav();
  update();
}
