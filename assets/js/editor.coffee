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
    pCH = $('#panelCurrentHotspot')
    find_pano pano_id, pCS, (pano_path) ->
      pCS.removeClass('hide')
      pCH.removeClass('hide')
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
        hotspot_sync()
    return

  window.hotspot_sync = (hotspot_name) ->
    return if !krpano

    pCH = $('#panelCurrentHotspot')
    list_hotspots = ->
      pCH.removeClass('hide')
      pCH.find('.current-hotspot').removeClass('hide')
      $('#btnAddHotspot').prop('disabled', false)
      hotspot_count = krpano.get 'hotspot.count'
      $('#panelCurrentHotspot .hotspots').empty()
      for i in [0...hotspot_count]
        name = krpano.get 'hotspot['+i+'].name'
        anchor = $('<a class="select-hotspot" href="#">'+name+'</a>')
        anchor.data('hotspot', name)
        $('#panelCurrentHotspot .hotspots').append($('<li />').append(anchor))

    if hotspot_name
      to = krpano.get 'hotspot['+hotspot_name+'].to'
      to = /^panos:(\d+)$/.exec(to)
      return if !to
      pano_id = to[1]
      find_pano pano_id, pCH, ->
        $('#btnRemoveHotspot').data('hotspot', hotspot_name)
        pCH.find('.hotspot-name').text(hotspot_name)
        $('#btnRemoveHotspot').prop('disabled', false)
        fov = krpano.get 'view.fov'
        krpano.call 'looktohotspot('+hotspot_name+', '+fov+')'
        list_hotspots()
    else
      list_hotspots()

    return

  window.pano_click = (s) ->
    pCH = $('#panelCurrentHotspot')
    pCH.find('.pano-img').attr 'src', (i, attr) -> $(this).data('default')
    pCH.find('.hotspot-name').text (i, text) -> $(this).data('default')
    $('#btnRemoveHotspot').prop('disabled', true)
    return

  pano_is_ready = (krpano) ->
    window.krpano = krpano

    krpano.set 'events.onloadcomplete', 'js(pano_sync(get(scene[get(xml.scene)].pano-id)))'
    krpano.set 'events.onclick', 'js(pano_click(s))'

    window.hotspot =
      interval: null
      ondown: (hotspot) ->
        window.hotspot.interval = window.setInterval ->
          krpano.call 'screentosphere(mouse.x, mouse.y, hotspot['+hotspot+'].ath, hotspot['+hotspot+'].atv)'
        , 30
        return
      onup: (hotspot) ->
        fov = krpano.get 'view.fov'
        krpano.call 'looktohotspot('+hotspot+', '+fov+')'
        $('#pano-selector').modal('show')
        window.clearInterval window.hotspot.interval
        return

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
      params =
        ath: krpano.get 'view.hlookat'
        atv: krpano.get 'view.vlookat'
        fov: krpano.get 'view.fov'
        scene: krpano.get 'xml.scene'
        rand: Math.random()
      path = '/tours/'+tour_id+'?'+$.param(params)
      krpano.call "loadpano('"+path+"', null, REMOVESCENES | IGNOREKEEP, BLEND(1))"
      toastr['success'] 'Tour reloaded.'

    $(document).on 'click', '.select-scene', ->
      krpano.call 'loadscene('+$(this).data('scene')+')'

    $(document).on 'click', '.select-hotspot', ->
      hotspot_sync $(this).data('hotspot')

  embedpano
    swf: "/swf/krpano.swf"
    xml: "/tours/" + tour_id
    target: "tour"
    html5: "auto"
    onready: pano_is_ready
