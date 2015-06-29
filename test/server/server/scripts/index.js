var loopback = require('loopback');
var ds = loopback.createDataSource("mysql", {
	"database": "rikki-tikki",
	"username": "rt-test",
	"password": "<%qI=dozA95W#(o",
	"name": "mysql",
	"connector": "mysql"
});
  
// Discover and build models from INVENTORY table
ds.discoverModelDefinitions({views: true, schema:'rikki-tikki'}, function (err, res) {
  console.log(res);
  process.exit();
});