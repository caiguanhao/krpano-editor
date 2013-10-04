tour = require '../lib/tour'

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
          when 'edit' then 'tours/edit'
        if view
          req.session.messages.push status
          res.render view, { tours: tours }
        else
          next()
      else
        next()

  app.post '/tours', (req, res) ->
    tour.add client, req, (status) ->
      req.session.messages.push status
      if status.error
        res.render 'tours/new', { body: req.body }
      else
        res.render 'tours/new'

  app.post '/tours/:id', (req, res, next) ->
    tour.update client, req, next, (status, tours) ->
      req.session.messages.push status
      if status.error
        res.render 'tours/edit', { body: req.body, tours: tours }
      else
        res.redirect '/tours/' + tours.id
