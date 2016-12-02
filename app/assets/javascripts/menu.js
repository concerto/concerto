function menuCollapse() {
  var nav = $("nav");
  if (nav.hasClass("minimized")) {
    nav.removeClass("minimized");
  } else {
    nav.addClass("minimized");
  }
}
