fs  = require 'fs-extra'
{_} = require 'lodash'
_path = require 'path'
RouteItem = require './RouteItem'
{EventEmitter} = require 'events'
class RouteManager extends EventEmitter
  'use strict'
  routes:[]
  constructor:->
    fs.ensureDir "#{app_root || '.'}/views", =>
      fs.ensureDir "#{app_root || '.'}/routes", =>
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
      _routes = @getpaths "#{app_root || '.'}/views"
    catch e
      return callback? e
    console.log _routes
    callback? null, _routes
  formatRoute:(path)->
    path
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
    console.log fs.readdirSync dir
    if (list = fs.readdirSync dir).length
      for name in list
        console.log name
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
          paths.push @getpaths "#{app_root || '.'}#{_path.sep}#{file}"
        else
          itemName = name.split('.')[0]
          # we only handle Jade files
          continue unless (name.match /^[^_]+[a-zA-Z0-9_\.]+\.jade+$/)?
          routeItem =
            name: itemName
            file_type: 'jade'
            query_method: if (itemName is 'index') then 'find' else 'findOne'
            route_file: "#{app_root || '.'}/#{_path.join 'routes', dir.replace(/\/?views+/,''), itemName}"
            template_file: "#{app_root || '.'}/#{_path.join dir.replace(/\/?views+/,''), itemName}"
            route: @formatRoute _path.join dir.replace(/\/?views+/,''), itemName
          paths.push routeItem
    _.flatten paths
  @getInstance: ->
    @__instance ?= new @  
module.exports = RouteManager