exports.list = (client, req, next, callback) ->

  tour_id = req.params.id

  if tour_id
    key = 'tours:' + tour_id
    client.exists key, (err, exists) ->
      if err or exists == 0
        next()
        return
      client.hgetall key, (err, tour) ->
        callback { error: err }, tour
    return

  client.lrange 'tours', 0, -1, (err, _tours) ->
    if _tours.length == 0
      callback { error: err}
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

exports.add = (client, req, callback) ->

  tour_name = req.body.name.trim()
  tour_desc = req.body.desc.trim()

  err_msg = switch true
    when tour_name.length == 0 then 'Name must not be empty.'
    when tour_name.length > 30 then 'Name is too long. (<=30)'
    when tour_desc.length > 100 then 'Description is too long. (<=100)'

  if err_msg
    callback { error: err_msg }
    return

  tour_id = client.incr 'tours:count', (err, id) ->
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

      callback { info: 'Successfully created a tour.' }

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

      tour_name = req.body.name.trim()
      tour_desc = req.body.desc.trim()

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
        callback { info: 'Successfully updated a tour.' }, tour
