/**
 * show.js
 * Route Handler File
 */
var _app_ref;
var render = function(res, model) {
  console.log(module.exports.templatePath);
 res.render( module.exports.templatePath, model, function(e,html) {
   res.send(html);
 }); 
};

var showHandler = function(req, res, next) {
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
  app.get("/objects/:id/show", showHandler);
};

module.exports.collectionName = "objects/:id/show";
module.exports.queryMethod = "findOne";
module.exports.templatePath = "/objects/show";
module.exports.query = {};