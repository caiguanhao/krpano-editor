jQuery ($) ->
  hotspot_new = 'hotspot_new'

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
        hotspot_panel_return_default()
        hotspot_sync()
    return

  window.hotspot_sync = (hotspot_name, follow_hotspot) ->
    return if !krpano

    pCH = $('#panelCurrentHotspot')
    list_hotspots = ->
      pCH.removeClass('hide')
      pCH.find('.current-hotspot').removeClass('hide')
      $('#btnAddHotspot').prop('disabled', false)
      hotspot_count = krpano.get 'hotspot.count'
      $('#panelCurrentHotspot .hotspots').empty()
      if hotspot_count == 0
        $('#panelCurrentHotspot .hotspots').append('<li><a class="select-hotspot" href="#">No hotspots.</a></li>')
      for i in [0...hotspot_count]
        name = krpano.get 'hotspot['+i+'].name'
        anchor = $('<a class="select-hotspot" href="#">'+name+'</a>')
        anchor.data('hotspot', name)
        $('#panelCurrentHotspot .hotspots').append($('<li />').append(anchor))

    if hotspot_name
      to = krpano.get 'hotspot['+hotspot_name+'].linkedscene'
      to = /^panos:(\d+)$/.exec(to)
      return if !to
      pano_id = to[1]
      find_pano pano_id, pCH, ->
        window.current_hotspot = hotspot_name
        pCH.find('.hotspot-name').text(hotspot_name)
        $('#btnRemoveHotspot').prop('disabled', false)
        if follow_hotspot
          fov = krpano.get 'view.fov'
          krpano.call 'looktohotspot('+hotspot_name+', '+fov+')'
        list_hotspots()
    else
      list_hotspots()

    return

  hotspot_panel_return_default = ->
    pCH = $('#panelCurrentHotspot')
    pCH.find('.pano-img').attr 'src', (i, attr) -> $(this).data('default')
    pCH.find('.hotspot-name').text (i, text) -> $(this).data('default')
    pCH.find('.pano-link').attr 'href', (i, attr) -> $(this).data('default')
    $('#btnRemoveHotspot').prop('disabled', true)
    hotspot_count = krpano.get 'hotspot.count'
    for i in [0...hotspot_count]
      krpano.set 'hotspot['+i+'].ondown', 'js(hotspot.ondown('+i+'))'
      krpano.set 'hotspot['+i+'].onup', 'js(hotspot.onup('+i+'))'

  window.pano_click = () ->
    hotspot_panel_return_default()
    return

  pano_is_ready = (krpano) ->
    window.krpano = krpano

    krpano.set 'events.onloadcomplete', 'js(pano_sync(get(scene[get(xml.scene)].pano-id)))'
    krpano.set 'events.onclick', 'js(pano_click())'

    window.hotspot =
      interval: null
      ondown: (hotspot) ->
        hotspot = krpano.get 'hotspot['+hotspot+'].name' if /^\d+$/.test(hotspot)
        hotspot_sync hotspot
        window.hotspot.interval = window.setInterval ->
          krpano.call 'screentosphere(mouse.x, mouse.y, hotspot['+hotspot+'].ath, hotspot['+hotspot+'].atv)'
        , 30
        return
      onup: (hotspot) ->
        fov = krpano.get 'view.fov'
        krpano.call 'looktohotspot('+hotspot+', '+fov+')'
        window.clearInterval window.hotspot.interval
        if hotspot == hotspot_new
          $('#pano-selector').modal('show')
        return
      click: (hotspot) ->
        if `krpano.get('hotspot['+hotspot+'].ath') != krpano.get('hotspot['+hotspot+']._ath') ||
        krpano.get('hotspot['+hotspot+'].ath') != krpano.get('hotspot['+hotspot+']._ath')`
          $('#hotspot-adjust').modal('show')
        else
          linkedscene = krpano.get 'hotspot['+hotspot+'].linkedscene'
          if linkedscene
            krpano.call 'tween(hotspot['+hotspot+'].scale,0.25,0.5)'
            krpano.call 'tween(hotspot['+hotspot+'].oy,-20,0.5)'
            krpano.call 'tween(hotspot['+hotspot+'].alpha,0,0.5)'
            krpano.call 'looktohotspot('+hotspot+')'
            krpano.call 'loadscene('+linkedscene+',null,MERGE,BLEND(1))'
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

    $('#linkToPano').click (e) ->
      path = window.pano_path
      return if !path
      to_id = $('#pano-list').find('a.thumbnail.active:first').data('id')
      ath = krpano.get 'hotspot['+hotspot_new+'].ath'
      atv = krpano.get 'hotspot['+hotspot_new+'].atv'
      $.post path + '/connect', { to: to_id, ath: ath, atv: atv }, (res) ->
        $('#pano-selector').modal('hide')
        $.each res, (a, b) -> toastr[a](b)
        $('#btnReload').trigger('click')

    $('#btnRemoveHotspot').click (e) ->
      pano_id = window.pano_id
      pano_path = '/tours/' + tour_id + '/panoramas/' + pano_id
      hotspot = window.current_hotspot
      return if !krpano or !pano_id or !hotspot
      to = krpano.get 'hotspot['+hotspot+'].linkedscene'
      $.ajax
        url: pano_path + '/hotspots'
        type: 'DELETE'
        data: { to: to }
      .done (res) ->
        $.each res, (a, b) -> toastr[a](b)
        $('#btnReload').trigger('click')

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

    $(document).on 'click', '.select-scene', (e) ->
      e.preventDefault()
      krpano.call 'loadscene('+$(this).data('scene')+')'

    $(document).on 'click', '.select-hotspot', (e) ->
      e.preventDefault()
      hotspot = $(this).data('hotspot')
      return if !hotspot
      hotspot_sync hotspot, true

    move_hotspot = (move_relevant) ->
      pano_id = window.pano_id
      pano_path = '/tours/' + tour_id + '/panoramas/' + pano_id
      hotspot = window.current_hotspot
      return if !krpano or !pano_id or !hotspot
      to = krpano.get 'hotspot['+hotspot+'].linkedscene'
      $.ajax
        url: pano_path + '/hotspots'
        type: 'PUT'
        data:
          _atv: krpano.get 'hotspot['+hotspot+']._atv'
          _ath: krpano.get 'hotspot['+hotspot+']._ath'
          to: to
          atv: krpano.get 'hotspot['+hotspot+'].atv'
          ath: krpano.get 'hotspot['+hotspot+'].ath'
          move_relevant: if move_relevant then 'yes' else 'no'
      .done (res) ->
        $('#hotspot-adjust').modal('hide')
        $.each res, (a, b) -> toastr[a](b)
        $('#btnReload').trigger('click')

    $('#btnMoveCurrent').click (e) ->
      move_hotspot false

    $('#btnMoveRelevant').click (e) ->
      move_hotspot true

  embedpano
    swf: "/swf/krpano.swf"
    xml: "/tours/" + tour_id
    target: "tour"
    html5: "auto"
    onready: pano_is_ready
