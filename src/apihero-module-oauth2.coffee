sess = require 'express-session'
uuid = require 'node-uuid'
bodyParser = require 'body-parser'
cookie = require 'cookie-parser'
method = require 'method-override'
passport = require 'passport'

exports.init = (app,options)->
  app.use bodyParser
  app.use cookie
  app.use method
  app.use sess
    genid: (req)->
      uuid.v4()
    secret: options.secret || 'secret key string'
    cookie: 
      secure: options.secure || false
  app.use passport.initialize()