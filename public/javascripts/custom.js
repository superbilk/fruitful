$(document).ready(function () {

  $(document).foundation();
  updateGraph();

  $("a#up").click(function(){
    if ($(this).hasClass('disabled')) {
      return false;
    }
    $("a").addClass("disabled");
    $('#resultmodal').foundation('reveal', 'open');
    $.post("/up", {url: getAccountName()});
    enableButtonsDelayed(5);
    removeResultAlertDelayed(2);
    return false;
  });

  $("a#down").click(function(){
    if ($(this).hasClass('disabled')) {
      return false;
    }
    $("a").addClass("disabled");
    $('#resultmodal').foundation('reveal', 'open');
    $.post("/down", {url: getAccountName()});
    enableButtonsDelayed(5);
    removeResultAlertDelayed(2);
    return false;
  });

  $("a#editsave").click(function(){
    var posturl = window.location.pathname + "/edit";
    $.post(posturl, $("#editnameform").serialize(), function(){
      $("#accountname").text($("#editname").val());
    });
    $("#editmodal").foundation('reveal', 'close');
    return false;
  });

  $("a#editmodal-link").click(function(){
    $('#editmodal').foundation('reveal', 'open');
    $('input#editname').focus();
    return false;
  });

  function enableButtonsDelayed(delaySeconds){
    window.setTimeout(enableButtons, delaySeconds*1000);
  };

  function enableButtons(){
    $("a").removeClass("disabled");
  };

  function removeResultAlertDelayed(delaySeconds){
    window.setTimeout(removeResultAlert, delaySeconds*1000);
  };

  function removeResultAlert(){
    $('#resultmodal').foundation('reveal', 'close');
  };

  function updateGraph(){
    $.getJSON("/graph.json", {url: getAccountName(), width: $("#responsivebox").width()}, function(data) {
      $("#graph").sparkline(data, {
        type: 'tristate',
        disableTooltips: true,
        posBarColor: "#457a1a",
        negBarColor: "#970b0e",
        height: "10px"
      });
    });

  };

  function getAccountName() {
    var pathArray = window.location.pathname.split( '/' );
    return pathArray[1];
  };

  setInterval(function () {
    $.getJSON("/votes_count.json", function(data) {
      $("#votes_count").text(data);
    });

    $.getJSON("/accounts_count.json", function(data) {
      $("#accounts_count").text(data);
    });

    updateGraph();
  }, 5000);

});

// remove URL bar from mobile devices
// http://mobile.tutsplus.com/tutorials/mobile-web-apps/remove-address-bar/
function hideAddressBar()
{
  if(!window.location.hash)
  {
      if(document.height < window.outerHeight)
      {
          document.body.style.height = (window.outerHeight + 50) + 'px';
      }

      setTimeout( function(){ window.scrollTo(0, 1); }, 50 );
  }
}

window.addEventListener("load", function(){ if(!window.pageYOffset){ hideAddressBar(); } } );
window.addEventListener("orientationchange", hideAddressBar );
