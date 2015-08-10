jwt = require 'jws'
AuthorizationError = require('./errors/authorizationerror')

clientInfo = (client) ->
  if !client
    return client
  client.id + ',' + client.name

userInfo = (user) ->
  if !user
    return user
  user.id + ',' + user.username + ',' + user.email

isExpired = (tokenOrCode) ->
  issuedTime = tokenOrCode.issuedAt and tokenOrCode.issuedAt.getTime() or -1
  now = Date.now()
  expirationTime = tokenOrCode.expiredAt and tokenOrCode.expiredAt.getTime() or -1
  if expirationTime == -1 and issuedTime != -1 and typeof tokenOrCode.expiresIn == 'number'
    expirationTime = issuedTime + tokenOrCode.expiresIn * 1000
  now > expirationTime

###*
# Normalize items to string[]
# @param {String|String[]} items
# @returns {String[]}
###

normalizeList = (items) ->
  if !items
    return []
  list = undefined
  if Array.isArray(items)
    list = [].concat(items)
  else if typeof items == 'string'
    list = items.split(/[\s,]+/g).filter(Boolean)
  else
    throw new Error('Invalid items: ' + items)
  list

###*
# Normalize scope to string[]
# @param {String|String[]} scope
# @returns {String[]}
###

normalizeScope = (scope) ->
  normalizeList scope

###*
# Check if one of the scopes is in the allowedScopes array
# @param {String[]} allowedScopes An array of required scopes
# @param {String[]} scopes An array of granted scopes
# @returns {boolean}
###

isScopeAllowed = (allowedScopes, tokenScopes) ->
  allowedScopes = normalizeScope(allowedScopes)
  tokenScopes = normalizeScope(tokenScopes)
  if allowedScopes.length == 0
    return true
  i = 0
  n = allowedScopes.length
  while i < n
    if tokenScopes.indexOf(allowedScopes[i]) != -1
      return true
    i++
  false

###*
# Check if the requested scopes are covered by authorized scopes
# @param {String|String[]) requestedScopes
# @param {String|String[]) authorizedScopes
# @returns {boolean}
###

isScopeAuthorized = (requestedScopes, authorizedScopes) ->
  requestedScopes = normalizeScope(requestedScopes)
  authorizedScopes = normalizeScope(authorizedScopes)
  if requestedScopes.length == 0
    return true
  i = 0
  n = requestedScopes.length
  while i < n
    if authorizedScopes.indexOf(requestedScopes[i]) == -1
      return false
    i++
  true

validateClient = (client, options, next) ->
  options = options or {}
  next = next or (err) ->
    err
  err = undefined
  if options.redirectURI
    redirectURIs = client.callbackUrls or client.redirectUris or client.redirectURIs or []
    if redirectURIs.length > 0
      matched = false
      i = 0
      n = redirectURIs.length
      while i < n
        if options.redirectURI.indexOf(redirectURIs[i]) == 0
          matched = true
          break
        i++
      if !matched
        err = new AuthorizationError('Unauthorized redirectURI: ' + options.redirectURI, 'access_denied')
        return next(err) or err
  if options.scope
    authorizedScopes = normalizeList(client.scopes)
    requestedScopes = normalizeList(options.scope)
    if authorizedScopes.length and !isScopeAuthorized(requestedScopes, authorizedScopes)
      err = new AuthorizationError('Unauthorized scope: ' + options.scope, 'access_denied')
      return next(err) or err
  # token or code
  if options.responseType
    authorizedTypes = normalizeList(client.responseTypes)
    if authorizedTypes.length and authorizedTypes.indexOf(options.responseType) == -1
      err = new AuthorizationError('Unauthorized response type: ' + options.responseType, 'access_denied')
      return next(err) or err
  # authorization_code, password, client_credentials, refresh_token,
  # urn:ietf:params:oauth:grant-type:jwt-bearer
  if options.grantType
    authorizedGrantTypes = normalizeList(client.grantTypes)
    if authorizedGrantTypes.length and authorizedGrantTypes.indexOf(options.grantType) == -1
      err = new AuthorizationError('Unauthorized grant type: ' + options.grantType, 'access_denied')
      return next(err) or err
  null

generateJWT = (payload, secret, alg) ->
  body = 
    header: alg: alg or 'HS256'
    secret: secret
    payload: payload
  jwt.sign body

buildTokenParams = (accessToken, token) ->
  params = expires_in: accessToken.expiresIn
  scope = accessToken.scopes and accessToken.scopes.join(' ')
  if scope
    params.scope = scope
  if accessToken.refreshToken
    params.refresh_token = accessToken.refreshToken
  if typeof token == 'object'
    for p of token
      if p != 'id' and !params[p] and token[p]
        params[p] = token[p]
  params

module.exports =
  clientInfo: clientInfo
  userInfo: userInfo
  isExpired: isExpired
  normalizeList: normalizeList
  validateClient: validateClient
  isScopeAllowed: isScopeAllowed
  isScopeAuthorized: isScopeAuthorized
  generateJWT: generateJWT
  buildTokenParams: buildTokenParams
