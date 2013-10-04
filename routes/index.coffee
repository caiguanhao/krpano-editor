tour = require '../lib/tour'
panorama = require '../lib/panorama'

module.exports = (app, client) ->

  app.get '/', (req, res) ->
    res.render 'index'

  app.get '/tours/new', (req, res) ->
    res.render 'tours/new'

  app.get '/tours/:id?/(:action)?', (req, res, next) ->
    tour.list client, req, next, (status, tours) ->
      if tours instanceof Array
        req.session.messages.push status
        res.render 'tours/list', { tours: tours || [] }
      else if tours
        view = switch req.params.action
          when undefined then 'tours/show'
          when 'edit', 'delete' then 'tours/' + req.params.action
        if view
          req.session.messages.push status
          res.render view, { tours: tours }
        else
          next()
      else
        req.session.messages.push { warning: 'No virutal tours.' }
        res.redirect '/'

  app.post '/tours', (req, res, next) ->
    tour.add client, req, next, (status, tours) ->
      req.session.messages.push status
      if status.error
        res.render 'tours/new', { body: req.body }
      else
        res.redirect 'tours/' + tours.id

  app.post '/tours/:id', (req, res, next) ->
    tour.update client, req, next, (status, tours) ->
      req.session.messages.push status
      if status.error
        res.render 'tours/edit', { body: req.body, tours: tours }
      else
        res.redirect '/tours/' + tours.id

  app.delete '/tours/:id', (req, res, next) ->
    if !req.body.confirm or req.body.confirm != 'yes'
      res.redirect '/tours/' + req.params.id
      return
    tour.delete client, req, next, (status) ->
      req.session.messages.push status
      res.redirect '/tours'

  app.get '/tours/:tour_id/panoramas/new', (req, res, next) ->
    panorama.tour_exists client, req, next, (status, tours) ->
      req.session.messages.push status
      res.render 'panoramas/new', { tours: tours }

  app.post '/tours/:tour_id/panoramas', (req, res, next) ->
    panorama.add client, req, next, (status, tours) ->
      req.session.messages.push status
      res.render 'panoramas/new', { body: req.body, tours: tours }
