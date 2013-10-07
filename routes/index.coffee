tour = require '../lib/tour'
panorama = require '../lib/panorama'

module.exports = (app, client) ->

  app.get '/', (req, res) ->
    res.render 'index'

  app.get '/tours/new', (req, res) ->
    res.render 'tours/new'

  app.get '/tours/:id.json', (req, res, next) ->
    tour.list client, req, next, (status, tours, panos) ->
      res.send { tours: tours, panos: panos || [] }

  app.get '/tours/:id.xml', (req, res, next) ->
    tour.list client, req, next, (status, tours, panos) ->
      res.render 'xml/tour', { tours: tours, panos: panos || [] }

  app.get '/tours/:id?/(:action)?', (req, res, next) ->
    tour.list client, req, next, (status, tours, panos) ->
      if tours instanceof Array
        req.session.messages.push status
        res.render 'tours/list', { tours: tours || [] }
      else if tours
        view = switch req.params.action
          when undefined then 'tours/show'
          when 'edit', 'delete' then 'tours/' + req.params.action
        if view
          req.session.messages.push status
          res.render view, { tours: tours, panos: panos || [], view: req.session.tour_view || 'tour' }
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
    panorama.add client, req, next, (status, tours, panos) ->
      req.session.messages.push status
      if status.error
        res.render 'panoramas/new', { body: req.body, tours: tours }
      else
        res.redirect '/tours/' + tours.id + '/panoramas/' + panos.id

  app.get '/tours/:tour_id/panoramas/:pano_id.xml', (req, res, next) ->
    panorama.pano_exists client, req, next, (status, tours, panos) ->
      res.render 'xml/pano', { tours: tours, panos: panos }

  app.get '/tours/:tour_id/panoramas/:pano_id/:action?', (req, res, next) ->
    panorama.pano_exists client, req, next, (status, tours, panos) ->
      view = switch req.params.action
        when undefined then 'panoramas/show'
        when 'edit', 'delete' then 'panoramas/' + req.params.action
      if view
        req.session.messages.push status

        params = { tours: tours, panos: panos }
        switch req.params.action
          when 'edit'
            path = if panos.image then req.app.get('public_dir') + panos.image else ''
            panorama.image_check path, (results) ->
              params['image_check'] = results
              res.render view, params
          else
            res.render view, params
      else
        next()

  app.post '/tours/:tour_id/panoramas/:pano_id', (req, res, next) ->
    if req.body.make_thumbs
      panorama.make_thumbs client, req, next, (status, tours, panos) ->
        req.session.messages.push status
        res.redirect '/tours/' + tours.id + '/panoramas/' + panos.id + '/edit'
      return
    panorama.update client, req, next, (status, tours, panos) ->
      req.session.messages.push status
      if status.error
        res.render 'panoramas/edit', { body: req.body, tours: tours, panos: panos }
      else
        res.redirect '/tours/' + tours.id + '/panoramas/' + panos.id

  app.delete '/tours/:tour_id/panoramas/:pano_id', (req, res, next) ->
    if !req.body.confirm or req.body.confirm != 'yes'
      res.redirect '/tours/' + req.params.tour_id + '/panoramas/' + req.params.pano_id
      return
    panorama.delete client, req, next, (status) ->
      req.session.messages.push status
      res.redirect '/tours/' + req.params.tour_id
