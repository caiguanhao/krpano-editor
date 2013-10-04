tour = require '../lib/tour'

module.exports = (app, client) ->

  app.get '/', (req, res) ->
    res.render 'index'

  app.get '/tours/new', (req, res) ->
    res.render 'tours/new'

  app.post '/tours', (req, res) ->
    tour.add client, req, (status) ->
      if status.error
        res.render 'tours/new', { body: req.body, status: status }
      else
        res.render 'tours/new', { status: status }
