$(document).ready(function () {

  $(document).foundation();
  updateGraph();

  $("a#up").click(function(){
    if ($(this).hasClass('disabled')) {
      return false;
    }
    $("a").addClass("disabled");
    $('#resultmodalpositive').foundation('reveal', 'open');
    $.post(window.location.pathname + "/up");
    enableButtonsDelayed(5);
    removeResultAlertDelayed(2);
    return false;
  });

  $("a#down").click(function(){
    if ($(this).hasClass('disabled')) {
      return false;
    }
    $("a").addClass("disabled");
    $('#resultmodalnegative').foundation('reveal', 'open');
    $.post(window.location.pathname + "/down");
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

  $("a#logoutmodal-link").click(function(){
    $('#logoutmodal').foundation('reveal', 'open');
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
    $('#resultmodalpositive').foundation('reveal', 'close');
    $('#resultmodalnegative').foundation('reveal', 'close');
  };

  function updateGraph(){
    $.getJSON(window.location.pathname + "/graph.json", {width: $("#responsivebox").width()}, function(data) {
      if (data.length>0) {
        $("#tristategraph").sparkline(data, {
          type: 'tristate',
          disableTooltips: true,
          posBarColor: "#5da423",
          negBarColor: "#c60f13",
          barWidth: "8"
        });
      };
    });
    $.getJSON(window.location.pathname + "/piechart_today.json", function(data) {
      if (data.length>0) {
        $("#piecharts").show();
        $("#td-piechart").sparkline(data, {
          type: 'pie',
          disableTooltips: true,
          sliceColors: ["#5da423", "#c60f13"]
        });
      };
    });
    $.getJSON(window.location.pathname + "/piechart_yesterday.json", function(data) {
      if (data.length>0) {
        $("#piecharts").show();
        $("#yd-piechart").sparkline(data, {
          type: 'pie',
          disableTooltips: true,
          sliceColors: ["#5da423", "#c60f13"]
        });
      };
    });
    $.getJSON(window.location.pathname + "/piechart_week.json", function(data) {
      if (data.length>0) {
        $("#piecharts").show();
        $("#wk-piechart").sparkline(data, {
          type: 'pie',
          disableTooltips: true,
          sliceColors: ["#5da423", "#c60f13"]
        });
      };
    });
  };

  setInterval(function () {
    updateGraph();
  }, 10*1000);

  setInterval(function () {
    $.getJSON("/texts.json", function(data) {
      $("#question").text(data.question);
      $("#up").text(data.positive);
      $("#down").text(data.negative);
    });
  }, 25*60*1000);

});

// remove URL bar from mobile devices
/mobile/i.test(navigator.userAgent) && !window.location.hash && setTimeout(function () {
  window.scrollTo(0, 1);
}, 500);
