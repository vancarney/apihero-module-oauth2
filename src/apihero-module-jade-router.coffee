fs      = require 'fs'
_       = require 'lodash'
class TemplateRouter
  constructor:(app, options)->
    # verbose = options.verbose
    # fs.readdirSync("./routes").forEach (name)->
      # return if name.match /^\./ 
      # verbose && console.log "\n   #{name}:"
      # obj = require "./../routes/#{name}"
      # name = obj.name || name
      # prefix = obj.prefix || ''
      # app = express()
      # # allow specifying the view engine
# 
      # # before middleware support
      # if obj.before
        # path = "/#{name}/:#{name}_id"
        # app.all path, obj.before
        # verbose && console.log '     ALL %s -> before', path
        # path = "/#{name}/:#{name}_id/*"
        # app.all path, obj.before
        # verbose && console.log '     ALL %s -> before', path
      # # generate routes based
      # # on the exported methods
      # for key of obj
        # # "reserved" exports
        # continue if ~['name', 'prefix', 'engine', 'before'].indexOf key
        # # route exports
        # switch key
          # when 'show'
            # method = 'get'
            # path = "/#{name}/:#{id}"
          # when 'index'
            # method = 'get'
            # path = "/#{if name != 'index' then name else ''}"
          # else
            # throw new Error "unrecognized route: #{name}.#{key}"
        # path = prefix + path
        # app[method](path, obj[key])
        # verbose && console.log "#{method.toUpperCase()} #{path} -> #{key}"
      # parent.use app
      
module.exports.init = (app,options)->
  views = ['./views']
  app.on 'ahero-initialized', (modules)=>
    done = _.after modules.length, (views)=>
      console.log views
      app.set 'view engine', 'jade'
      app.set 'views', views
    _.each _.keys modules, (name)=>
      done views unless (module = require name).hasOwnProperty 'paths' and module.paths.length > 1
      for path in module.paths
        views.concat path if (path.match /\.jade+$/)?
      done views