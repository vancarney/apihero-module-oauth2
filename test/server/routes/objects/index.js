/**
 * index.js
 * Route Handler File
 */
var _app_ref;
var render = function(res, model) {
  console.log(module.exports.templatePath);
 res.render( module.exports.templatePath, model, function(e,html) {
   res.send(html);
 }); 
};

var indexHandler = function(req, res, next) {
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
  app.get("/s", indexHandler);
};

module.exports.collectionName = "s";
module.exports.queryMethod = "find";
module.exports.templatePath = "/objects/index";
module.exports.query = {};