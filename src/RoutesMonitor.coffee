fs = require 'fs'
{_} = require 'lodash'
{AbstractMonitor} = require 'api-hero'
class RoutesMonitor extends AbstractMonitor
  __path:'./views'
  constructor:->
    RoutesMonitor.__super__.constructor.call @
    @startPolling 3
  refresh:(callback)->
    ex = []
    RouteManager.getInstance().load (e, routes)=>
      list = _.compact _.map routes, (v)=> 
        _path = "#{v.route_file}.js"
        try 
          (stats = fs.statSync _path)
        catch e
          return {name:v.route_file}
        return null
      for value in list
        if 0 <= (idx = @getNames().indexOf value.name)
          ex.push value
      @__collection.addAll list if (list = _.difference list, ex).length
      console.log list
      callback? e, list
  startPolling:->
    console.log 'startPolling'
    @__iVal ?= fs.watch @__path, (event, filename) =>
      try
        RouteManager.getInstance().load()
      catch e
        console.log e
      finally
        @refresh()
module.exports = RoutesMonitor
RouteManager = require './RouteManager'