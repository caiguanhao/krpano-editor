fs = require 'fs'
gm = require 'gm'

tour_exists = (client, req, next, callback) ->
  tour_id = req.params.tour_id
  if !tour_id then next(); return
  key = 'tours:' + tour_id
  client.exists key, (err, exists) ->
    if err or exists == 0 then next(); return
    client.hgetall key, (err, tour) ->
      callback { error: err }, tour

exports.tour_exists = tour_exists

pano_exists = (client, req, next, callback) ->
  tour_id = req.params.tour_id
  pano_id = req.params.pano_id
  if !tour_id or !pano_id then next(); return
  tour_key = 'tours:' + tour_id
  pano_key = 'panos:' + pano_id
  client.exists tour_key, (err, exists) ->
    if err or exists == 0 then next(); return
    client.exists pano_key, (err, exists) ->
      if err or exists == 0 then next(); return
      client.exists tour_key + ':panos', (err, exists) ->
        if err or exists == 0 then next(); return
        client.sismember tour_key + ':panos', pano_key, (err, ismember) ->
          if err or ismember == 0 then next(); return
          client.hgetall tour_key, (err, tour) ->
            client.hgetall pano_key, (err, pano) ->
              callback { error: err }, tour, pano

exports.pano_exists = pano_exists

save_upload_image = (image_path, app, tour, pano, callback) ->
  if !image_path then callback {}, tour, pano, ''; return
  gm(image_path).format (err, value) ->
    if err
      fs.unlinkSync image_path
      callback { error: err.toString() }, tour, pano
    else if value != 'JPEG'
      fs.unlinkSync image_path
      callback { error: 'Image is not an JPEG file.' }, tour, pano
    else
      md5 = require('crypto').createHash 'md5'
      stream = fs.ReadStream image_path
      stream.on 'data', (d) -> md5.update d
      stream.on 'end', ->
        md5sum = md5.digest('hex')
        new_path = app.get('upload_dir') + '/' + md5sum[0]
        fs.mkdir new_path, '0755', (error) ->
          if error and error.errno != 47 then callback { error: error }, tour, pano; return
          new_path += '/' + md5sum[1]
          fs.mkdir new_path, '0755', (error) ->
            if error and error.errno != 47 then callback { error: error }, tour, pano; return
            new_path += '/' + md5sum + '.jpg'
            fs.rename image_path, new_path, (error) ->
              if error then callback { error: error }, tour, pano; return
              callback {}, tour, pano, new_path.replace app.get('public_dir'), ''

thumbnail = (path, thumb_size) ->
  return '' if !path
  path += '.' if !/\.[^\/]+?$/.test(path)
  path = /^(.*)(\..*)$/.exec(path)
  path[1] + '_' + thumb_size + 'px' + path[2].replace /\.$/, ''

exports.thumbnail = thumbnail

make_thumbnail = (image_path, callback) ->
  gm(image_path).format (err, value) ->
    if err or value != 'JPEG' then callback { error: err }; return
    gm(image_path).resize(250, 125, '!').noProfile().quality(90).write thumbnail(image_path, 250), (error) ->
      callback { error: err }

image_check = (image_path, callback) ->
  if !image_path then callback []; return
  results = [
    { danger: "Not a valid JPEG." },
    { danger: "Invalid spherical panoramic image: aspect ratio is not 2:1." },
    { danger: "The resolution of the image is either too low or too high." },
    { danger: "At least one thumbnail is missing." },
  ]
  gm(image_path).format (err, value) ->
    if err or value != 'JPEG' then callback results
    else
      results[0] = { success: "A valid JPEG." }
      gm(image_path).size (err, size) ->
        if err then callback results
        if size.height * 2 == size.width
          results[1] = { success: "A valid spherical panoramic image with 2:1 aspect ratio." }
        if size.width >= 2000 and size.width <= 12000
          results[2] = { success: "The resolution of the image is neither too low nor too high." }
        fs.exists thumbnail(image_path, 250), (exists) ->
          if exists then results[3] = { success: "Thumbnails exist." }
          callback results

exports.image_check = image_check

exports.add = (client, req, next, callback) ->
  tour_exists client, req, next, (status, tour) ->

    pano_name = if req.body.name then req.body.name.trim() else ''
    pano_desc = if req.body.desc then req.body.desc.trim() else ''
    image = req.files.image

    err_msg = switch true
      when pano_name.length == 0 then 'Name must not be empty.'
      when pano_name.length > 30 then 'Name is too long. (<=30)'
      when pano_desc.length > 100 then 'Description is too long. (<=100)'

    path = ''
    if req.files.image
      path = req.files.image.path 
      if req.files.image.size == 0
        fs.unlinkSync path
        path = ''

    if err_msg
      callback { error: err_msg }, tour
      return

    save_upload_image path, req.app, tour, null, (status, tour, pano, new_path) ->
      if status.error then callback { error: status.error }, tour; return
      client.incr 'panos:count', (err, id) ->
        if err then callback { error: err }, tour; return
        tour_key = 'tours:' + tour.id
        pano_key = 'panos:' + id
        client.lpush 'panos', pano_key
        client.sadd tour_key + ':panos', pano_key
        client.hmset pano_key,
          id: id
          created_at: Math.round(Date.now() / 1000)
          name: pano_name
          desc: pano_desc
          image: new_path

        callback { success: 'Successfully created a panorama.' }, tour, { id: id }

exports.update = (client, req, next, callback) ->
  pano_exists client, req, next, (status, tour, pano) ->

    pano_name = if req.body.name then req.body.name.trim() else ''
    pano_desc = if req.body.desc then req.body.desc.trim() else ''
    pano_image = if req.body.image then req.body.image.trim() else ''

    err_msg = switch true
      when pano_name.length == 0 then 'Name must not be empty.'
      when pano_name.length > 30 then 'Name is too long. (<=30)'
      when pano_desc.length > 100 then 'Description is too long. (<=100)'
      when pano_image.length > 256 then 'Image path is too long. (<=256)'

    path = ''
    if req.files and req.files.new_image
      path = req.files.new_image.path
      if req.files.new_image.size == 0
        fs.unlinkSync path
        path = ''

    if err_msg
      callback { error: err_msg }, tour, pano
      return

    save_upload_image path, req.app, tour, pano, (status, tour, pano, new_path) ->
      if new_path and new_path.length > 0 then pano_image = new_path
      if pano_name == pano.name and pano_desc == pano.desc and pano_image == pano.image
        callback { warning: 'Nothing changes.' }, tour, pano
      else
        pano_key = 'panos:' + pano.id
        client.hmset pano_key,
          name: pano_name
          desc: pano_desc
          image: pano_image

        callback { success: 'Successfully updated a panorama.' }, tour, pano

exports.delete = (client, req, next, callback) ->
  pano_exists client, req, next, (status, tour, pano) ->
    tour_key = 'tours:' + tour.id
    pano_key = 'panos:' + pano.id
    client.del pano_key
    client.srem tour_key + ':panos', pano_key
    client.lrem 'panos', 0, pano_key

    callback { success: 'Successfully deleted a panorama.' }

exports.make_thumbs = (client, req, next, callback) ->
  pano_exists client, req, next, (status, tour, pano) ->
    image = pano.image
    if image
      image = req.app.get('public_dir') + image
      make_thumbnail image, (status) ->
        if status.error then callback { error: status.error }, tour, pano; return
        callback { success: 'Successfully generated thumbnails.' }, tour, pano
    else
      callback { warning: 'No need to generate thumbnails.' }, tour, pano
