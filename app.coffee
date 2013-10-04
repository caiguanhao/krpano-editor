express = require 'express'
redis = require 'redis'
assets = require 'connect-assets'

app = express()

client = redis.createClient()

app.set 'port', process.env.PORT || 3000
app.set 'view engine', 'jade'
app.set 'views', __dirname + '/views'

app.use express.logger('dev')
app.use express.static(__dirname + '/public')
app.use express.bodyParser()
app.use assets
  buildDir: './public' # do not use full path
app.use express.cookieParser()
app.use express.session
  secret: 'LWOM0nhYrnVwm93p'
app.use (req, res, next) ->
  req.session.messages = [] if !req.session.messages
  res.locals.messages = req.session.messages
  next()

routes = require './routes'

routes app, client

app.use (req, res) ->
  res.status(404).render '404'

app.listen app.get('port'), ->
  console.log 'Express server listening on port ' + app.get('port')
