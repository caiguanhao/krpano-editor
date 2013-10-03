express = require 'express'
assets = require 'connect-assets'

app = express()

app.set 'port', process.env.PORT || 3000
app.set 'view engine', 'jade'
app.set 'views', __dirname + '/views'

app.use express.logger('dev')
app.use express.static(__dirname + '/public')
app.use assets
  buildDir: './public' # do not use full path

index = require './routes/index'

app.get '/', index

app.use (req, res) ->
  res.status(404).render '404'

app.listen app.get('port'), ->
  console.log 'Express server listening on port ' + app.get('port')
