util = require 'util'

###*
# Module dependencies.
###

OAuth2Error = require('./oauth2error')

###*
# Inherit from `OAuth2Error`.
###

###*
# `AuthorizationError` error.
#
# @api public
###

AuthorizationError = (message, code, uri, status) ->
  if !status
    switch code
      when 'invalid_request'
        status = 400
      when 'invalid_client'
        status = 401
      when 'unauthorized_client'
        status = 403
      when 'access_denied'
        status = 403
      when 'unsupported_response_type'
        status = 400
      when 'invalid_scope'
        status = 400
      when 'temporarily_unavailable'
        status = 503
  OAuth2Error.call @, message, code, uri, status
  Error.captureStackTrace @, arguments.callee
  @name = 'AuthorizationError'
  return

util.inherits AuthorizationError, OAuth2Error

###*
# Expose `AuthorizationError`.
###

module.exports = AuthorizationError