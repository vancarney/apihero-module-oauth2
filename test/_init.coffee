{_}             = require 'lodash'
fs              = require 'fs'
path            = require 'path'
{should,expect} = require 'chai'
global._        = _
global.should   = should
global.expect   = expect
global.app_root = './test/server'
lt        = require 'loopback-testing'
server    = require './server/server/server'

describe 'init app', ->
  it 'should emit a `initialized` event', (done)=>
    server.once 'ahero-initialized', =>
      global.app = server
      # global.api_options  = require '../lib/classes/config/APIOptions'
      done.apply @, arguments
  it 'should have a reference set on Loopback', =>
    expect(app.ApiHero).to.exist
    
  it 'should create index route', (done)=>
    fs.stat "#{app_root}/routes/index.js", done
    
  it 'should create a new route when view is created', (done)=>
    fs.writeFile "#{app_root}/views/testing.jade", 'h1 Test', =>
      process.nextTick =>
        fs.stat "#{app_root}/routes/testing.js", done
        
  it 'should remove a route when view is removed', (done)=>
    fs.unlink "#{app_root}/views/testing.jade", =>
      process.nextTick =>
        fs.stat "#{app_root}/routes/testing.js", (e)=>
          expect(e).to.not.be null
                
  after (done)=>
    fs.unlink "#{app_root}/routes/index.js", =>
    fs.unlink "#{app_root}/routes/testing.js", => done()
