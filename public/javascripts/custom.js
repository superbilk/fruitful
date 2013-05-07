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
      $(".hiddenchart").show();
      $("#tristategraph").sparkline(data["tristategraph"], {
        type: 'tristate',
        disableTooltips: true,
        posBarColor: "#5da423",
        negBarColor: "#c60f13",
        zeroBarColor: "#909090",
        barWidth: "8"
      });
      $("#weekday-barchart").sparkline(data["weekdayBarchart"], {
        type: 'bar',
        disableTooltips: true,
        zeroColor: "#909090",
        nullColor: "#909090",
        stackedBarColor: ["#c60f13", "#5da423"],
        barWidth: "8"
      });
      $("#activity-barchart").sparkline(data["activityBarchart"], {
        type: 'bar',
        disableTooltips: true,
        barWidth: "8"
      });
      $("#mo-piechart").sparkline(data["piechartMonth"], {
        type: 'pie',
        disableTooltips: true,
        sliceColors: ["#5da423", "#c60f13", "#909090"]
      });
      $("#wk-piechart").sparkline(data["piechartWeek"], {
        type: 'pie',
        disableTooltips: true,
        sliceColors: ["#5da423", "#c60f13", "#909090"]
      });
      $("#yd-piechart").sparkline(data["piechartYesterday"], {
        type: 'pie',
        disableTooltips: true,
        sliceColors: ["#5da423", "#c60f13", "#909090"]
      });
      $("#td-piechart").sparkline(data["piechartToday"], {
        type: 'pie',
        disableTooltips: true,
        sliceColors: ["#5da423", "#c60f13", "#909090"]
      });
    });
  };

  function updateText() {
    $.getJSON("/texts.json", function(data) {
      $("#question").text(data.question);
      $("#positive").text(data.positive);
      $("#negative").text(data.negative);
    });
  };

  // remove URL bar from mobile devices
  /mobile/i.test(navigator.userAgent) && !window.location.hash && setTimeout(function () {
    window.scrollTo(0, 1);
  }, 500);

  setInterval(function () {
    updateGraph();
  }, 5*60*1000);

  setInterval(function () {
    updateText();
  }, 7*60*1000);

});

