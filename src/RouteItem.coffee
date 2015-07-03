fs = require 'fs'
{_} = require 'lodash'
apihero = require 'api-hero'
class RouteItem
  constructor:(@route_item)->
  save:(callback)->
    fs.write @route_item.route_path, @template( @route_item ), (e)=>
      callback? (e?)
RouteItem.__template__ = """
/**
 * <%= name %>.js
 * Route Handler File
 */
var _app_ref;
var render = function(res, model) {
 res.render( module.exports.templatePath ); 
};

var <%= name %>Handler = function(req, res, next) {
  var funcName = module.exports.queryMethod || 'find';
  var collectionName = ((name = module.exports.collectionName) == "") ? null : name;
  
  if (collectionName == null) {
    render(res, {});
  }
  
  _app_ref.models[collectionName][funcName]( module.exports.query, function(e,record) {
    if (e != null) {
      console.log(e);
      return res.sendStatus(500);
    }
    
    render(res,record);
  });
};

module.exports.init = function(app) {
  _app_ref = app;
  app.get("<%= route %>", <%= name %>Handler);
};

module.exports.collectionName = "<%= route %>";
module.exports.queryMethod = "<%= query_method %>";
module.exports.templatePath = "<%= template_file %>";
module.exports.query = {};
"""
RouteItem::template = _.template RouteItem.__template__