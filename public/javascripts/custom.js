$(document).ready(function () {

  $(this).foundation();
  updateGraph();

  $("a.vote").click(function(){
    if ($(this).hasClass('disabled')) {
      return false;
    }
    $(this).addClass("disabled");
    $('#resultmodal').foundation('reveal', 'open');
    $.post(window.location.pathname + "/vote", { vote: $(this).data("vote") } );
    console.log($(this).data("vote"));
    enableButtonsDelayed(5);
    removeResultAlertDelayed(2);
    return false;
  });

  $("a.setLanguage").click(function(){
    var posturl = window.location.pathname + "/language";
    $.post(posturl, { language: $(this).data("language") }, function(){
      updateText();
    });
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
    updateGraph();
  };

  function removeResultAlertDelayed(delaySeconds){
    window.setTimeout(removeResultAlert, delaySeconds*1000);
  };

  function removeResultAlert(){
    $('#resultmodal').foundation('reveal', 'close');
  };

  function updateGraph(){
    $.getJSON(window.location.pathname + "/graph.json", { width: $("#responsivebox").width() }, function(data) {
      $("#piecharts").show();
      $("#tristategraph").sparkline(data["tristateGraph"], {
        type: 'tristate',
        disableTooltips: true,
        posBarColor: "#5da423",
        negBarColor: "#c60f13",
        zeroBarColor: "#909090",
        barWidth: "8"
      });
      $("#mo-piechart").sparkline(data["pieChartMonth"], {
        type: 'pie',
        disableTooltips: true,
        sliceColors: ["#5da423", "#c60f13", "#909090"]
      });
      $("#wk-piechart").sparkline(data["pieChartWeek"], {
        type: 'pie',
        disableTooltips: true,
        sliceColors: ["#5da423", "#c60f13", "#909090"]
      });
      $("#yd-piechart").sparkline(data["pieChartYesterday"], {
        type: 'pie',
        disableTooltips: true,
        sliceColors: ["#5da423", "#c60f13", "#909090"]
      });
      $("#td-piechart").sparkline(data["pieChartToday"], {
        type: 'pie',
        disableTooltips: true,
        sliceColors: ["#5da423", "#c60f13", "#909090"]
      });
    });
  };

  function updateText() {
    $.getJSON("/texts.json", function(data) {
      $("#question").text(data.question);
      $("#up").text(data.positive);
      $("#down").text(data.negative);
    });
  };

  setInterval(function () {
    updateGraph();
  }, 5*60*1000);

  setInterval(function () {
    updateText();
  }, 7*60*1000);

});

// remove URL bar from mobile devices
/mobile/i.test(navigator.userAgent) && !window.location.hash && setTimeout(function () {
  window.scrollTo(0, 1);
}, 500);
