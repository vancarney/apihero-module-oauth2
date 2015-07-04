fs  = require 'fs-extra'
{_} = require 'lodash'
_path = require 'path'
RouteItem = require './RouteItem'
{EventEmitter} = require 'events'
class RouteManager extends EventEmitter
  'use strict'
  routes:[]
  _viewsDir: "#{app_root || '.'}#{_path.sep}views"
  _routesDir: "#{app_root || '.'}#{_path.sep}routes"
  constructor:->
    fs.ensureDir @_viewsDir, =>
      fs.ensureDir @_routesDir, =>
        @load (e, routes)=>
          return if e?
          @routes = routes
          @emit 'initialized', @routes
  getRoute:(route)->
    _.where @routes, route_file: route
  createRoute:(routing, callback)->
    (new RouteItem routing).save callback
  destroyRoute:(route, callback)->
  listRoutes:->
    @routes
  load:(callback)->
    try
      _routes = @getpaths @_viewsDir
    catch e
      return callback? e
    # console.log _routes
    callback? null, _routes
  formatRoute:(fname)->
    fname
    # handles index as base path
    .replace /index/, '/'
    # handles all sub-docs as being views on an item
    .replace /^(\/?[a-zA-Z0-9_]{1,}\/+)+(edit|index|show)$/, "$1:id/$2"
    # tidies up any doubled slashes
    .replace /\/\//,'/'
    # removes trailing slash
    .replace /^([a-zA-Z0-9_])+\/+$/, '$1'
  getpaths:(dir)->
    paths = []
    if (list = fs.readdirSync dir).length
      for name in list
        continue if (name.match /^\./)?
        file = _path.join dir, name
        try
          # attempt to get stats on the file
          stat = fs.statSync file
        catch e
          throw new Error e
          return false
        if stat?.isDirectory()
          # skips folders prepended with `_`
          continue if _path.basename(file).match /^_+/
          # # walks this directory and adds results to array
          paths.push @getpaths file
        else
          itemName = name.split('.')[0]
          # we only handle Jade files
          continue unless (name.match /^[^_]+[a-zA-Z0-9_\.]+\.jade+$/)?
          p = new RegExp @_viewsDir.replace( /\//,'\/')
          routeItem =
            name: itemName
            file_type: 'jade'
            query_method: if (itemName is 'index') then 'find' else 'findOne'
            route_file: "./#{_path.join @_routesDir, _path.basename(dir).replace(/views+/,''), itemName}"
            template_file: _path.join dir.split(/views+/).pop(), itemName
            route: @formatRoute _path.join _path.basename(dir).replace(/views+/,''), itemName
          paths.push routeItem
    _.flatten paths
  @getInstance: ->
    @__instance ?= new @  
module.exports = RouteManager