panorama = require './panorama'

exports.list = (client, req, next, callback) ->

  tour_id = req.params.id

  if tour_id
    key = 'tours:' + tour_id
    client.exists key, (err, exists) ->
      if err or exists == 0
        next()
        return
      client.hgetall key, (err, tour) ->
        client.scard key + ':panos', (err, num) ->
          if err or num == 0 then callback { error: err }, tour; return
          client.get key + ':entry', (err, entry) ->
            tour.entry = entry
            client.sismember key + ':panos', entry, (err, ismember) ->
              tour.has_entry = ismember == 1
              panos = []
              client.smembers key + ':panos', (err, members) ->
                count = 0
                members.forEach (member) ->
                  client.hgetall member, (err, pano) ->
                    pano_id = if pano then pano.id else ''
                    client.smembers 'panos:' + pano_id + ':connections', (err, members) ->
                      if pano
                        pano.thumb = panorama.thumbnail(pano.image, 250)
                        pano.entry = entry == 'panos:' + pano.id
                        pano.connections = members
                        panos.push pano
                      count += 1
                      if count == num
                        callback { error: err }, tour, panos
      if req.query.view
        req.session.tour_view = switch req.query.view
          when 'tour', 'list', 'graph' then req.query.view
    return

  client.lrange 'tours', 0, -1, (err, _tours) ->
    if _tours.length == 0
      callback { error: err }
      return

    tours = []
    _tours.forEach (tour) ->
      client.hgetall tour, (err, tour) ->
        if err
          callback { error: err }
        else
          tours.push tour

        if tours.length == _tours.length
          callback { error: err }, tours

exports.add = (client, req, next, callback) ->

  tour_name = if req.body.name then req.body.name.trim() else ''
  tour_desc = if req.body.desc then req.body.desc.trim() else ''

  err_msg = switch true
    when tour_name.length == 0 then 'Name must not be empty.'
    when tour_name.length > 30 then 'Name is too long. (<=30)'
    when tour_desc.length > 100 then 'Description is too long. (<=100)'

  if err_msg
    callback { error: err_msg }
    return

  client.incr 'tours:count', (err, id) ->
    if err
      callback { error: err }
    else
      key = 'tours:' + id

      client.lpush 'tours', key
      client.hmset key,
        id: id
        created_at: Math.round(Date.now() / 1000)
        name: tour_name
        desc: tour_desc

      callback { success: 'Successfully created a tour.' }, { id: id }

exports.update = (client, req, next, callback) ->

  tour_id = req.params.id

  key = 'tours:' + tour_id
  client.exists key, (err, exists) ->
    if err or exists == 0
      next()
      return

    client.hgetall key, (err, tour) ->
      if err
        next()
        return

      tour_name = if req.body.name then req.body.name.trim() else ''
      tour_desc = if req.body.desc then req.body.desc.trim() else ''

      err_msg = switch true
        when tour_name.length == 0 then 'Name must not be empty.'
        when tour_name.length > 30 then 'Name is too long. (<=30)'
        when tour_desc.length > 100 then 'Description is too long. (<=100)'

      if err_msg
        callback { error: err_msg }, tour
        return

      if tour_name == tour.name and tour_desc == tour.desc
        callback { warning: 'Nothing changes.' }, tour
      else
        client.hmset key,
          name: tour_name
          desc: tour_desc
        callback { success: 'Successfully updated a tour.' }, tour

exports.delete = (client, req, next, callback) ->

  tour_id = req.params.id

  key = 'tours:' + tour_id
  client.exists key, (err, exists) ->
    if err or exists == 0
      next()
      return

    client.hgetall key, (err, tour) ->
      if err
        next()
        return

      client.del key
      client.lrem 'tours', 0, key

      callback { success: 'Successfully deleted a tour.' }

exports.tour_xml_params = (req, params) ->
  isNumber = (n) -> !isNaN(parseFloat(n)) && isFinite(n);
  ath = req.query.ath
  atv = req.query.atv
  fov = req.query.fov
  scene = req.query.scene
  params.view = []
  if isNumber(ath) and -180 < ath < 180
    params.view.push 'view.hlookat='+ath
  if isNumber(atv) and -90 < atv < 90
    params.view.push 'view.vlookat='+atv
  if isNumber(fov) and 0 < fov < 179
    params.view.push 'view.fov='+fov
  params.view = params.view.join('&')
  params.scene = scene
  params
