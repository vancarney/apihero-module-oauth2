sess = require 'express-session'
uuid = require 'node-uuid'
bodyParser = require 'body-parser'
cookie = require 'cookie-parser'
method = require 'method-override'
passport = require 'passport'

exports.init = (app,options)->
  app.use bodyParser.urlencoded extended: true
  app.use bodyParser.json()
  app.use cookie()
  # app.use method
  app.use sess
    genid: (req)->
      uuid.v4()
    secret: options.secret || 'secret key string'
    resave: true,
    saveUninitialized: true
    cookie: 
      secure: options.secure || false
  app.use passport.initialize()
  require('./oauth') app, options
