if (history && history.pushState) {
  $(function () {
    $('a.browse_feedlink').live('click', function () {
      $.getScript(this.href);
      history.pushState(null, document.title, this.href);
      return false;
    });
  
    $(window).bind("popstate", function () {
      $.getScript(location.href);
    });
  })
}