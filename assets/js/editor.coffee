jQuery ($) ->
  window.pano_sync = (pano_id) ->
    window.pano_id = pano_id
    location = '/tours/' + tour_id + '/panoramas/' + pano_id
    $.getJSON location, (json) ->
      pCS = $('#panelCurrentScene').removeClass('hide')
      pCS.find('.pano-link').attr('href', location)
      pCS.find('.pano-img').attr('src', json.panos.thumb)
      pCS.find('.pano-name').text(json.panos.name)
      pCS.find('.pano-desc').text(json.panos.desc)

  pano_is_ready = (krpano) ->
    krpano.set 'events.onloadcomplete', 'js(pano_sync(get(scene[get(xml.scene)].pano-id)))'

    window.hotspot =
      interval: null
      ondown: (hotspot) ->
        window.hotspot.interval = window.setInterval ->
          krpano.call 'screentosphere(mouse.x, mouse.y, hotspot['+hotspot+'].ath, hotspot['+hotspot+'].atv)'
        , 30
      onup: (hotspot) ->
        $('#pano-selector').modal('show')
        window.clearInterval window.hotspot.interval

    $('#pano-selector').on 'show.bs.modal', ->
      $.getJSON '/tours/' + tour_id, (json) ->
        $('#pano-list').empty()
        $.each json.panos, (a, b) ->
          item = $('<a class="thumbnail" href="#"><img alt="'+b.name+'" src="'+b.thumb+
            '" class="thumbnail"><div class="caption"><h4>'+b.name+
              (if b.entry then ' <small class="glyphicon glyphicon-home"></small>' else '')+'</h4></div></a>')
          item.click (e) ->
            e.preventDefault()
            $(this).toggleClass('active')
            $('#pano-list').find('a.thumbnail').not(this).removeClass('active')
            $('#linkToPano').prop('disabled', $('#pano-list').find('a.thumbnail.active').length != 1)
          $('<div class="col-sm-6 col-md-4" />').append(item).appendTo('#pano-list')
      $('#linkToPano').click (e) ->
        #$.post('/tours/' + tour_id + '/panoramas/link')

    $('#btnAddHotspot').click (e) ->
      krpano.call 'addhotspot(hotspot1)'
      krpano.call 'hotspot[hotspot1].loadstyle(hotspotstyle_01)'
      krpano.set 'hotspot[hotspot1].ondown', 'js(hotspot.ondown(hotspot1))'
      krpano.set 'hotspot[hotspot1].onup', 'js(hotspot.onup(hotspot1))'

  embedpano
    swf: "/swf/krpano.swf"
    xml: "/tours/" + tour_id
    target: "tour"
    html5: "auto"
    onready: pano_is_ready
