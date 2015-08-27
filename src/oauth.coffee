module.exports = (app, options) ->

  ensureLoggedIn = ->
    (req, res, next) ->
      return res.redirect '/login' unless req.session.user and req.session.user.id
      next()
  oauth2orize = require "oauth2orize"
  passport = require "passport"
  BasicStrategy = require("passport-http").BasicStrategy
  ClientPasswordStrategy = require("passport-oauth2-client-password").Strategy
  BearerStrategy = require("passport-http-bearer").Strategy
  crypto = require "crypto"
  models = require './models'
  oauth2 = oauth2orize.createServer()
  oauth2.serializeClient (client, done) ->
    done null, client._id

  oauth2.deserializeClient (_id, done) ->
    models.OAuthClientApplication.findById _id, (err, client) ->
      return done(err)  if err
      done null, client


  oauth2.grant oauth2orize.grant.code((client, redirectURI, user, ares, done) ->
    
    # var code = utils.uid(16);
    now = new Date().getTime()
    code = crypto.createHmac("sha1", "access_token").update([ client.id, now ].join()).digest("hex")
    ac = new models.OAuthAuthorizationCode(
      code: code
      client_id: client.id
      redirect_uri: redirectURI
      user_id: client.user_id
      scope: ares.scope
    )
    ac.save (err) ->
      return done(err)  if err
      done null, code

  )
  oauth2.exchange oauth2orize.exchange.code((client, code, redirectURI, done) ->
    models.OAuthAuthorizationCode.findOne
      code: code
    , (err, code) ->
      return done(err)  if err
      return done(null, false)  if client._id.toString() isnt code.client_id.toString()
      return done(null, false)  if redirectURI isnt code.redirect_uri
      
      # var token = utils.uid(256);
      now = new Date().getTime()
      token = crypto.createHmac("sha1", "access_token").update([ client._id, now ].join()).digest("hex")
      at = new models.OAuthToken(
        oauth_token: token
        user_id: code.user_id
        client_id: client._id
        scope: code.scope
      )
      at.save (err) ->
        return done(err)  if err
        done null, token


  )
  passport.use new BasicStrategy((username, password, done) ->
    models.OAuthClientApplication.findById username, (err, client) ->
      return done(err)  if err
      return done(null, false)  unless client
      return done(null, false)  unless client.secret is password
      done null, client

  )
  passport.use new ClientPasswordStrategy((clientId, clientSecret, done) ->
    models.OAuthClientApplication.findById clientId, (err, client) ->
      return done(err)  if err
      return done(null, false)  unless client
      return done(null, false)  unless client.secret is clientSecret
      done null, client

  )
  passport.use new BearerStrategy((accessToken, done) ->
    models.OAuthToken.findOne
      oauth_token: accessToken
    , (err, token) ->
      return done(err)  if err
      return done(null, false)  unless token
      # models.User.findById token.user_id, (err, user) ->
      app.dataSources[accessDB][accessModel].findById token.user_id, (err, user) ->
        return done(err)  if err
        return done(null, false)  unless user
        
        # to keep this example simple, restricted scopes are not implemented,
        # and this is just for illustrative purposes
        info = scope: "*"
        done null, user, info


  )
  
  # Move to routes ------------------------------------------------------------
  app.get "/authorize", ensureLoggedIn(), oauth2.authorization((clientID, redirectURI, done) ->
    console.log 'authorize'
    models.OAuthClientApplication.findById clientID, (err, client) ->
      return done(err)  if err
      return done(null, false)  unless client
      return done(null, false)  unless client.redirect_uri is redirectURI
      done null, client, redirectURI

  ), (req, res) ->
    console.log 'authorize'
    res.json
      transactionID: req.oauth2.transactionID
      user: req.user
      client: req.oauth2.client


  
  # res.render('dialog', {
  #   transactionID: req.oauth2.transactionID,
  #   user: req.user,
  #   client: req.oauth2.client
  # });
  app.post "/authorize/decision", ensureLoggedIn(), oauth2.decision()
  app.post "/token", passport.authenticate([ "basic", "oauth2-client-password" ],
    session: false
  ), oauth2.token(), oauth2.errorHandler()