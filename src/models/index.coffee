# helpers = require('../oauth2-helper')

module.exports = (app, options) ->
  loopback = app.loopback
  options = options or {}
  dataSource = options.dataSource
  if typeof dataSource == 'string'
    dataSource = app.dataSources[dataSource]
  oauth2 = require('./oauth2-models')(dataSource)
  userModel = loopback.findModel(options.userModel) or loopback.getModelByType(loopback.User)
  applicationModel = loopback.findModel(options.applicationModel) or loopback.getModelByType(loopback.Application)
  oAuthTokenModel = oauth2.OAuthToken
  oAuthAuthorizationCodeModel = oauth2.OAuthAuthorizationCode
  oAuthPermissionModel = oauth2.OAuthPermission
  oAuthTokenModel.belongsTo userModel,
    as: 'user'
    foreignKey: 'userId'
  oAuthTokenModel.belongsTo applicationModel,
    as: 'application'
    foreignKey: 'appId'
  oAuthAuthorizationCodeModel.belongsTo userModel,
    as: 'user'
    foreignKey: 'userId'
  oAuthAuthorizationCodeModel.belongsTo applicationModel,
    as: 'application'
    foreignKey: 'appId'
  oAuthPermissionModel.belongsTo userModel,
    as: 'user'
    foreignKey: 'userId'
  oAuthPermissionModel.belongsTo applicationModel,
    as: 'application'
    foreignKey: 'appId'
  getTTL = if typeof options.getTTL == 'function' then options.getTTL else ((responseType, clientId, resourceOwner, scopes) ->
    if typeof options.ttl == 'function'
      return options.ttl(responseType, clientId, resourceOwner, scopes)
    if typeof options.ttl == 'number'
      return options.ttl
    if typeof options.ttl == 'object' and options.ttl != null
      return options.ttl[responseType]
    switch responseType
      when 'code'
        return 300
      else
        return 14 * 24 * 3600
      # 2 weeks
    return
  )
  users = {}

  users.find = (id, done) ->
    userModel.findOne { where: id: id }, done
    return

  users.findByUsername = (username, done) ->
    userModel.findOne { where: username: username }, done
    return

  users.findByUsernameOrEmail = (usernameOrEmail, done) ->
    userModel.findOne { where: or: [
      { username: usernameOrEmail }
      { email: usernameOrEmail }
    ] }, done
    return

  users.save = (id, username, password, done) ->
    userModel.create {
      id: id
      username: username
      password: password
    }, done
    return

  clients = {}
  clients.find =
  clients.findByClientId = (clientId, done) ->
    applicationModel.findById clientId, done
    return

  token = {}

  token.find = (accessToken, done) ->
    oAuthTokenModel.findOne { where: id: accessToken }, done
    return

  token.findByRefreshToken = (refreshToken, done) ->
    oAuthTokenModel.findOne { where: refreshToken: refreshToken }, done
    return

  token.delete = (clientId, token, tokenType, done) ->
    where = appId: clientId
    if tokenType == 'access_token'
      where.id = token
    else
      where.refreshToken = token
    oAuthTokenModel.destroyAll where, done
    return

  token.save = (token, clientId, resourceOwner, scopes, refreshToken, done) ->
    tokenObj = undefined
    if arguments.length == 2 and typeof token == 'object'
      # save(token, cb)
      tokenObj = token
      done = clientId
    ttl = getTTL('token', clientId, resourceOwner, scopes)
    if !tokenObj
      tokenObj =
        id: token
        appId: clientId
        userId: resourceOwner
        scopes: scopes
        issuedAt: new Date
        expiresIn: ttl
        refreshToken: refreshToken
    tokenObj.expiresIn = ttl
    tokenObj.issuedAt = new Date
    tokenObj.expiredAt = new Date(tokenObj.issuedAt.getTime() + ttl * 1000)
    oAuthTokenModel.create tokenObj, done
    return

  code = {}
  code.findByCode =
  code.find = (key, done) ->
    oAuthAuthorizationCodeModel.findOne { where: id: key }, done
    return

  code.delete = (id, done) ->
    oAuthAuthorizationCodeModel.destroyById id, done
    return

  code.save = (code, clientId, redirectURI, resourceOwner, scopes, done) ->
    codeObj = undefined
    if arguments.length == 2 and typeof token == 'object'
      # save(code, cb)
      codeObj = code
      done = clientId
    ttl = getTTL('code', clientId, resourceOwner, scopes)
    if !codeObj
      codeObj =
        id: code
        appId: clientId
        userId: resourceOwner
        scopes: scopes
        redirectURI: redirectURI
    codeObj.expiresIn = ttl
    codeObj.issuedAt = new Date
    codeObj.expiredAt = new Date(codeObj.issuedAt.getTime() + ttl * 1000)
    oAuthAuthorizationCodeModel.create codeObj, done
    return

  permission = {}

  permission.find = (appId, userId, done) ->
    oAuthPermissionModel.findOne { where:
      appId: appId
      userId: userId }, done
    return

  ###
  # Check if a client app is authorized by the user
  ###

  permission.isAuthorized = (appId, userId, scopes, done) ->
    permission.find appId, userId, (err, perm) ->
      if err
        return done(err)
      if !perm
        return done(null, false)
      ok = helpers.isScopeAuthorized(scopes, perm.scopes)
      info = if ok then authorized: true else {}
      done null, ok, info
    return

  permission.addPermission = (appId, userId, scopes, done) ->
    oAuthPermissionModel.findOrCreate { where:
      appId: appId
      userId: userId }, {
      appId: appId
      userId: userId
      scopes: scopes
      issuedAt: new Date
    }, (err, perm, created) ->
      if created
        return done(err, perm, created)
      else
        if helpers.isScopeAuthorized(scopes, perm.scopes)
          return done(err, perm)
        else
          perm.updateAttributes { scopes: helpers.normalizeList(scopes) }, done
      return
    return

  # Adapter for the oAuth2 provider
  customModels = options.models or {}
  models = 
    users: customModels.users or users
    clients: customModels.clients or clients
    accessTokens: customModels.accessTokens or token
    authorizationCodes: customModels.authorizationCodes or code
    permissions: customModels.permission or permission
  models