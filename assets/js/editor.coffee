jQuery ($) ->
  find_pano = (pano_id, to_element, done) ->
    pano_path = '/tours/' + tour_id + '/panoramas/' + pano_id
    $.getJSON pano_path, (json) ->
      to_element.find('.pano-link').attr('href', pano_path)
      to_element.find('.pano-img').attr('src', json.panos.thumb)
      to_element.find('.pano-name').text(json.panos.name)
      to_element.find('.pano-desc').text(json.panos.desc)
      done pano_path

  window.pano_sync = (pano_id) ->
    pCS = $('#panelCurrentScene')
    find_pano pano_id, pCS, (pano_path) ->
      pCS.removeClass('hide')
      window.pano_id = pano_id
      window.pano_path = pano_path
      scene_count = krpano.get 'scene.count'
      current_scene = krpano.get 'xml.scene'
      $('#panelCurrentScene .scenes').empty()
      for i in [0...scene_count]
        name = krpano.get 'scene['+i+'].name'
        anchor = $('<a class="select-scene" href="#">'+krpano.get('scene['+i+'].title')+'</a>')
        if current_scene == name
          anchor.append('<span class="pull-right glyphicon glyphicon-check"></span>')
        anchor.data('scene', name)
        $('#panelCurrentScene .scenes').append($('<li />').append(anchor))

  window.hotspot_sync = (hotspot_name) ->
    return if !krpano
    to = krpano.get 'hotspot['+hotspot_name+'].to'
    to = /^panos:(\d+)$/.exec(to)
    return if !to
    pano_id = to[1]
    pCH = $('#panelCurrentHotspot').addClass('hide')
    find_pano pano_id, pCH, ->
      $('#btnRemoveHotspot').data('hotspot', hotspot_name)
      pCH.find('.hotspot-name').text(': ' + hotspot_name)
      pCH.removeClass('hide')

  pano_is_ready = (krpano) ->
    window.krpano = krpano

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
          return true if b.id == pano_id # continue if pano is current
          item = $('<a class="thumbnail" href="#"><img alt="'+b.name+'" src="'+b.thumb+
            '" class="thumbnail"><div class="caption"><h4>'+b.name+
              (if b.entry then ' <small class="glyphicon glyphicon-home"></small>' else '')+'</h4></div></a>')
          item.data 'id', b.id
          item.click (e) ->
            e.preventDefault()
            $(this).toggleClass('active')
            $('#pano-list').find('a.thumbnail').not(this).removeClass('active')
            $('#linkToPano').prop('disabled', $('#pano-list').find('a.thumbnail.active').length != 1)
          $('<div class="col-sm-6 col-md-4" />').append(item).appendTo('#pano-list')

    hotspot_new = 'hotspot_new'

    $('#linkToPano').click (e) ->
      path = window.pano_path
      return if !path
      to_id = $('#pano-list').find('a.thumbnail.active:first').data('id')
      ath = krpano.get 'hotspot['+hotspot_new+'].ath'
      atv = krpano.get 'hotspot['+hotspot_new+'].atv'
      $.post path + '/connect', { to: to_id, ath: ath, atv: atv }, (res) ->
        $('#pano-selector').modal('hide')
        $.each res, (a, b) -> toastr[a](b)

    $('#btnRemoveHotspot').click (e) ->
      pano_id = window.pano_id
      pano_path = '/tours/' + tour_id + '/panoramas/' + pano_id
      hotspot = $('#btnRemoveHotspot').data('hotspot')
      return if !krpano or !pano_id or !hotspot
      to = krpano.get 'hotspot['+hotspot+'].to'
      $.ajax
        url: pano_path + '/hotspots'
        type: 'DELETE'
        data: { to: to }
      .done (res) ->
        $('#panelCurrentHotspot').addClass('hide')
        $.each res, (a, b) -> toastr[a](b)

    $('#btnAddHotspot').click (e) ->
      krpano.call 'addhotspot('+hotspot_new+')'
      krpano.call 'hotspot['+hotspot_new+'].loadstyle(hotspotstyle_01)'
      krpano.set 'hotspot['+hotspot_new+'].ondown', 'js(hotspot.ondown('+hotspot_new+'))'
      krpano.set 'hotspot['+hotspot_new+'].onup', 'js(hotspot.onup('+hotspot_new+'))'
      krpano.set 'hotspot['+hotspot_new+'].ath', krpano.get('view.hlookat')
      krpano.set 'hotspot['+hotspot_new+'].atv', krpano.get('view.vlookat')

    $('#btnReload').click (e) ->
      $('#panelCurrentScene').addClass('hide')
      path = '/tours/'+tour_id+'?'+Math.random()
      krpano.call "loadpano('"+path+"', null, REMOVESCENES | IGNOREKEEP, BLEND(1))"

    $(document).on 'click', '.select-scene', ->
      krpano.call 'loadscene('+$(this).data('scene')+')'

  embedpano
    swf: "/swf/krpano.swf"
    xml: "/tours/" + tour_id
    target: "tour"
    html5: "auto"
    onready: pano_is_ready
