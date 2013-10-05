express = require 'express'
redis = require 'redis'
assets = require 'connect-assets'

app = express()

client = redis.createClient()

app.set 'port', process.env.PORT || 3000
app.set 'view engine', 'jade'
app.set 'views', __dirname + '/views'
app.set 'public_dir', __dirname + '/public'
app.set 'tmp_upload_dir', __dirname + '/tmp/uploads'
app.set 'upload_dir', __dirname + '/public/uploads'

app.use express.logger('dev')
app.use express.static(app.get 'public_dir')
app.use express.bodyParser
  uploadDir: app.get 'tmp_upload_dir'
app.use assets
  buildDir: './public' # do not use full path
app.use express.methodOverride()
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
