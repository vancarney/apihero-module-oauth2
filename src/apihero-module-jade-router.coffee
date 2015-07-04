fs      = require 'fs'
path    = require 'path'
_       = require 'lodash'

module.exports.init = (app,options)->
  views = ["#{app_root || '.'}/views"]
  _routes = []
  app.once 'ahero-initialized', =>
    done = _.after app.ApiHero.loadedModules.length, =>
      app.set 'view engine', 'jade'
      app.set 'views', views
      console.log "views: #{views}"
    _routeManager = RouteManager.getInstance().on 'initialized', (routes)=>
      _routes = routes
      generateRoute = (route)=>
        _routeManager.createRoute route, (e)->
          return console.log e if e?
          setTimeout (=>
            (require "#{route.route_file}").init app
          ), 1300
      # _.each _routes, (route)=>
        # generateRoute route
      app.ApiHero.createSyncInstance 'route', RoutesMonitor
      .addSyncHandler 'route', 'added', (op)=>
        _routeManager.load (e,r)=>
          generateRoute route[0] if (route = _.where r, route_file:op.name)?.length
      .addSyncHandler 'route', 'removed', (op)=>
        fs.unlink "#{op.name}.js", (e)=>
          console.log e if e?
    # call done if no modules need loading
    return done() unless app.ApiHero.loadedModules.length
    _.each app.ApiHero.loadedModules, (name)=>
      done() unless (module = require name).hasOwnProperty 'paths' and module.paths.length > 1
      for path in module.paths
        views.push path if (path.match /\.jade+$/)?
      views = _.uniq _.flatten views
      done() 
RouteManager  = require './RouteManager'
RoutesMonitor = require './RoutesMonitor'