$(document).ready(function () {

  $("a#up").click(function(){
    $("a").addClass("disabled");
    $('#result').foundation('reveal', 'open');
    $.post("/up");
    enableButtonsDelayed(5);
    removeResultAlertDelayed(4);
    return false;
  });

  $("a#down").click(function(){
    $("a").addClass("disabled");
    $('#result').foundation('reveal', 'open');
    $.post("/down");
    enableButtonsDelayed(5);
    removeResultAlertDelayed(4);
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
    $('#result').foundation('reveal', 'close');
  };

  // remove URL bar from mobile devices
  /mobile/i.test(navigator.userAgent) && !window.location.hash && setTimeout(function () {
    window.scrollTo(0, 1);
  }, 500);

  setInterval(function () {
    $.getJSON("votes_count.json", function(data) {
      $("#votes_count").text(data);
    });
  }, 5000);


});

