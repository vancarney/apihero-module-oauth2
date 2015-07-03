fs = require 'fs'
{_} = require 'lodash'
{AbstractMonitor} = require 'api-hero'
class RoutesMonitor extends AbstractMonitor
  __path:"#{app_root || '.'}/views"
  constructor:->
    RoutesMonitor.__super__.constructor.call @
    @refresh (e,collection)=>
      RouteManager.getInstance().load (e, routes)=>
        arr = collection.concat _.filter routes, (route)=>
          _.pluck(collection, 'name').indexOf route.route_file is -1
        @__collection.__list = arr
        @startPolling()
    # setTimeout (=>
      # unless _initialized
        # _initialized = true
        # console.log @getCollection()
        # @emit 'init', '0':'added':@getCollection()
    # ), 600
  refresh:(callback)->
    ex = []
    RouteManager.getInstance().load (e, routes)=>
      list = _.compact _.map routes, (v)=> 
        _path = "#{v.route_file}.js"
        try 
          (stats = fs.statSync _path)
        catch e
          # adds new item reference to list
          return {name:v.route_file}
        return null
        
      del = _.filter @getCollection(), (v)=>
        _.pluck( routes, 'route_file').indexOf( v.route_file ) is -1
        
      _.each del, (to_remove)=>
         @__collection.removeItemAt @getNames().indexOf to_remove.name
      # filters items from exclusion list and adds newly created items to collection
      @__collection.addAll list #if (list = _.difference list, ex).length
      # invokes callback
      callback? e, list
  startPolling:->
    @__iVal ?= fs.watch @__path, (event, filename) =>
      try
        RouteManager.getInstance().load()
      catch e
        console.log e
      finally
        @refresh()
module.exports = RoutesMonitor
RouteManager = require './RouteManager'