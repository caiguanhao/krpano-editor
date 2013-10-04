exports.add = (client, req, callback) ->

  tour_name = req.body.name.trim()
  tour_desc = req.body.desc.trim()

  err_msg = switch true
    when tour_name.length == 0 then 'Name must not be empty.'
    when tour_name.length > 30 then 'Name is too long. (<=30)'
    when tour_desc.length > 100 then 'Description is too long. (<=100)'

  if err_msg
    callback { error: err_msg }
  else
    callback { info: 'Successfully created a tour.' }
