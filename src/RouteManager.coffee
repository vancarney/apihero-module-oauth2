fs  = require 'fs-extra'
{_} = require 'lodash'
path = require 'path'
RouteItem = require './RouteItem'
{EventEmitter} = require 'events'
class RouteManager extends EventEmitter
  'use strict'
  routes:[]
  constructor:->
    fs.ensureDir './views'
    @load (e)=>
      return if e?
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
      @routes = @getpaths './views'
    catch e
      return callback? e
    # for route in @routes
      # console.log "#{route.name}: #{route.route_file}"
    callback? null, @routes
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
    if (list = fs.readdirSync dir).length
      for name in list
        continue if (name.match /^\./)?
        file = path.join dir, name
        try
          # attempt to get stats on the file
          stat = fs.statSync file
        catch e
          throw new Error e
          return false
        if stat?.isDirectory()
          # # walks this directory and adds results to array
          paths.push @getpaths "./#{file}"
        else
          itemName = name.split('.')[0]
          # we only handle Jade files
          continue unless (name.match /^[^_]+[a-zA-Z0-9_\.]+\.jade+$/)?
          routeItem =
            name: itemName
            query_method: if (itemName is 'index') then 'find' else 'findOne'
            route_file: "./#{path.join 'routes', dir.replace(/\/?views+/,''), itemName}"
            template_file: path.join dir.replace(/\/?views+/,''), itemName
            route: @formatRoute path.join dir.replace(/\/?views+/,''), itemName
          paths.push routeItem
    _.flatten paths
  @getInstance: ->
    @__instance ?= new @  
module.exports = RouteManager