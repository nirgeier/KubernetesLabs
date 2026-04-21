document$.subscribe(function() {
  var links = document.querySelectorAll(".md-sidebar--primary .md-nav__link");
  links.forEach(function(link) {
    var text = link.textContent.trim();
    if (text.includes("-")) {
       var newText = text.split("-")[0].trim();
       link.textContent = newText;
    }
  });
});
