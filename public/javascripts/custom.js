$(document).ready(function () {

  $("a#up").click(function(){
    $("a").addClass("disabled");
    $('#resultmodal').foundation('reveal', 'open');
    $.post("/up");
    enableButtonsDelayed(5);
    removeResultAlertDelayed(4);
    return false;
  });

  $("a#down").click(function(){
    $("a").addClass("disabled");
    $('#resultmodal').foundation('reveal', 'open');
    $.post("/down");
    enableButtonsDelayed(5);
    removeResultAlertDelayed(4);
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

  // remove URL bar from mobile devices
  /mobile/i.test(navigator.userAgent) && !window.location.hash && setTimeout(function () {
    window.scrollTo(0, 1);
  }, 500);

  setInterval(function () {
    $.getJSON("votes_count.json", function(data) {
      $("#votes_count").text(data);
    });
    $.getJSON("accounts_count.json", function(data) {
      $("#accounts_count").text(data);
    });
  }, 5000);

});
