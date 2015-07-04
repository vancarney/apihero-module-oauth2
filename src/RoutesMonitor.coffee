fs = require 'fs'
{_} = require 'lodash'
{AbstractMonitor} = require 'api-hero'
class RoutesMonitor extends AbstractMonitor
  __path:"#{app_root || '.'}/views"
  constructor:->
    RoutesMonitor.__super__.constructor.call @
    @__collection.on 'collectionChanged', (data) => @emit 'changed', data
    @refresh (e)=> @startPolling()
    # # @refresh (e)=>
      # # RouteManager.getInstance().load (e, routes)=>
        # # collection = @getCollection()
        # # routes = _.map (_.pluck routes, 'route_file'), (v)-> name:v
        # # arr = collection.concat _.filter routes, (route)=>
          # # _.pluck(collection, 'name').indexOf route is -1
        # # @__collection.__list = _.uniq arr
        # # @startPolling()
  handleRoutes:(routes)->
    list = []
    for route in routes
      _path = "#{route.route_file}.js"
      try 
        (stats = fs.statSync _path)
      catch e
        # adds new item reference to list
        list.push {name:route.route_file}
        continue
      unless 0 <= _.pluck( @__collection.__list, 'name').indexOf route.route_file
        @__collection.__list.push {name:route.route_file}
    list
  refresh:(callback)->
    RouteManager.getInstance().load (e, routes)=>
      list = @handleRoutes routes
      del = _.compact _.filter _.compact(@getCollection()), (v)=>
        return false if typeof v.name is 'undefined'
        _.pluck( routes, 'route_file').indexOf( v.name ) is -1
      _.each del, (to_remove)=>
         @__collection.removeItemAt @getNames().indexOf to_remove.nam
      @__collection.addAll list
      # invokes callback
      callback? e, list
  startPolling:->
    @__iVal ?= fs.watch @__path, => @refresh()
module.exports = RoutesMonitor
RouteManager = require './RouteManager'