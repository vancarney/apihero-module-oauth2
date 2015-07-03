fs = require 'fs-extra'
path = require 'path'
{_} = require 'lodash'
class RouteItem
  constructor:(@route_item)->
  save:(callback)->
    fs.ensureDir path.dirname( p = "#{@route_item.route_file}.js"), (e)=>
      return callback.apply @, arguments if e?
      fs.writeFile p, @template(@route_item), {flag:'wx'}, (e)=>
        callback?.apply @, arguments
RouteItem.__template__ = """
/**
 * <%= name %>.js
 * Route Handler File
 */
var _app_ref;
var render = function(res, model) {
  console.log(module.exports.templatePath);
 res.render( module.exports.templatePath, model, function(e,html) {
   res.send(html);
 }); 
};

var <%= name %>Handler = function(req, res, next) {
  var funcName = module.exports.queryMethod || 'find';
  var collectionName = ((name = module.exports.collectionName) == "") ? null : name;

  if (collectionName == null || _app_ref.models[collectionName] == void 0) {
    return render(res, {});
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
  app.get("/<%= route %>", <%= name %>Handler);
};

module.exports.collectionName = "<%= route %>";
module.exports.queryMethod = "<%= query_method %>";
module.exports.templatePath = "<%= template_file %>";
module.exports.query = {};
"""
RouteItem::template = _.template RouteItem.__template__
module.exports = RouteItem