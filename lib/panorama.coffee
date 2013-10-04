tour_exists = (client, req, next, callback) ->
  tour_id = req.params.tour_id
  if !tour_id then next(); return
  key = 'tours:' + tour_id
  client.exists key, (err, exists) ->
    if err or exists == 0 then next(); return
    client.hgetall key, (err, tour) ->
      callback { error: err }, tour

exports.tour_exists = tour_exists

exports.add = (client, req, next, callback) ->
  tour_exists client, req, next, (status, tour) ->

    pano_name = if req.body.name then req.body.name.trim() else ''
    pano_desc = if req.body.desc then req.body.desc.trim() else ''
    image = req.files.image

    err_msg = switch true
      when pano_name.length == 0 then 'Name must not be empty.'
      when pano_name.length > 30 then 'Name is too long. (<=30)'
      when pano_desc.length > 100 then 'Description is too long. (<=100)'
      when !req.files.image then 'Please select an image to upload.'

    fs = require 'fs'
    if req.files.image && req.files.image.size == 0
      fs.unlinkSync req.files.image.path
      err_msg = 'Please select an image to upload.'

    if err_msg
      callback { error: err_msg }, tour
      return

    callback { info: 'OK' }, tour
