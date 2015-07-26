{_}             = require 'lodash'
fs              = require 'fs'
path            = require 'path'
{should,expect} = require 'chai'
global._        = _
global.should   = should
global.expect   = expect
global.app_root = path.join __dirname, 'server'
lt        = require 'loopback-testing'
server    = require './server/server/server'

describe 'init app', ->
  @timeout 10000
  it 'should emit a `initialized` event', (done)=>
    server.once 'ahero-initialized', =>
      global.app = server
      expect(app.ApiHero).to.exist
      done.apply @, arguments
      
    
