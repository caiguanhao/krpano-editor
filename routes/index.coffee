tour = require '../lib/tour'

module.exports = (app, client) ->

  app.get '/', (req, res) ->
    res.render 'index'

  app.get '/tours/new', (req, res) ->
    res.render 'tours/new'

  app.get '/tours/:id?', (req, res, next) ->
    tour.list client, req, next, (status, tours) ->
      if tours instanceof Array
        res.render 'tours/list', { status: status, tours: tours || [] }
      else if tours
        res.render 'tours/show', { status: status, tours: tours }
      else
        next()

  app.post '/tours', (req, res) ->
    tour.add client, req, (status) ->
      if status.error
        res.render 'tours/new', { body: req.body, status: status }
      else
        res.render 'tours/new', { status: status }
