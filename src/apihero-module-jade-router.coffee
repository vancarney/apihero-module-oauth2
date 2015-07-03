fs      = require 'fs'
path    = require 'path'
_       = require 'lodash'

module.exports.init = (app,options)->
  views = ['./views']
  app.once 'ahero-initialized', =>
    done = _.after app.ApiHero.loadedModules.length, =>
      console.log views
      app.set 'view engine', 'jade'
      app.set 'views', views
      _routeManager = RouteManager.getInstance()
    app.ApiHero.createSyncInstance 'route', RoutesMonitor
    .addSyncHandler 'route', 'added', (op)=>
      _rm = RouteManager.getInstance()
      if (route = _rm.getRoute op.name)?.length
        _rm.createRoute route[0], (e)->
          return console.log e if e?
          setTimeout (=>
            (require "#{path.join process.cwd(), route[0].route_file}").init app
          ), 100
    return done() unless app.ApiHero.loadedModules.length
    _.each app.ApiHero.loadedModules, (name)=>
      done() unless (module = require name).hasOwnProperty 'paths' and module.paths.length > 1
      for path in module.paths
        views.push path if (path.match /\.jade+$/)?
      views = _.flatten views
      done() 
RouteManager  = require './RouteManager'
RoutesMonitor = require './RoutesMonitor'