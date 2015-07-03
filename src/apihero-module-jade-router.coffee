fs      = require 'fs'
path    = require 'path'
_       = require 'lodash'

module.exports.init = (app,options)->
  views = ['./views']
  app.once 'ahero-initialized', =>
    done = _.after app.ApiHero.loadedModules.length, =>
      app.set 'view engine', 'jade'
      app.set 'views', views
    _routeManager = RouteManager.getInstance().on 'initialized', =>
      console.log 'initialized'
      app.ApiHero.createSyncInstance 'route', RoutesMonitor
      .addSyncHandler 'route', 'added', (op)=>
        if (route = _routeManager.getRoute op.name)?.length
          _routeManager.createRoute route[0], (e)->
            return console.log e if e?
            setTimeout (=>
              (require "#{path.join process.cwd(), route[0].route_file}").init app
            ), 100
      .addSyncHandler 'route', 'removed', (op)=>
        fs.unlink "#{op.name}.js", (e)=>
          console.log e if e?
    return done() unless app.ApiHero.loadedModules.length
    _.each app.ApiHero.loadedModules, (name)=>
      done() unless (module = require name).hasOwnProperty 'paths' and module.paths.length > 1
      for path in module.paths
        views.push path if (path.match /\.jade+$/)?
      views = _.flatten views
      done() 
RouteManager  = require './RouteManager'
RoutesMonitor = require './RoutesMonitor'