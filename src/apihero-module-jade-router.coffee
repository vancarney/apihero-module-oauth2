fs      = require 'fs'
path    = require 'path'
_       = require 'lodash'

module.exports.init = (app,options)->
  views = ['./views']
  app.once 'ahero-initialized', =>
    done = _.after app.ApiHero.loadedModules.length, (views)=>
      app.set 'view engine', 'jade'
      app.set 'views', views
      _routeManager = RouteManager.getInstance()
    app.ApiHero.createSyncInstance 'route', RoutesMonitor
    .addSyncHandler 'route', 'added', (op)=>
      # console.log op
      tree = {}
    return done() unless app.ApiHero.loadedModules.length
    _.each app.ApiHero.loadedModules, (name)=>
      done views unless (module = require name).hasOwnProperty 'paths' and module.paths.length > 1
      for path in module.paths
        views.concat path if (path.match /\.jade+$/)?
      done views
RouteManager  = require './RouteManager'
RoutesMonitor = require './RoutesMonitor'