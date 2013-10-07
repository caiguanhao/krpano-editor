jQuery ($) ->
  krpano = $('#tour #krpanoSWFObject')[0]
  window.hotspot =
    interval: null
    ondown: (hotspot) ->
      window.hotspot.interval = window.setInterval ->
        krpano.call 'screentosphere(mouse.x, mouse.y, hotspot['+hotspot+'].ath, hotspot['+hotspot+'].atv)'
      , 30
    onup: (hotspot) ->
      window.clearInterval window.hotspot.interval
  $('#btnAddHotspot').unbind('click').click (e) ->
    krpano.call 'addhotspot(hotspot1)'
    krpano.call 'hotspot[hotspot1].loadstyle(hotspotstyle_01)'
    krpano.set 'hotspot[hotspot1].ondown', 'js(hotspot.ondown(hotspot1))'
    krpano.set 'hotspot[hotspot1].onup', 'js(hotspot.onup(hotspot1))'
