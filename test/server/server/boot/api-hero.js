var hero = require('api-hero');
module.exports = function(app) {

	app.once('ahero-initialized', function() {
		// app.ApiHero.loadedModules = ['apihero-module-jade-router'];
// 		
		// console.log(app.listeners());
		app.emit('ahero-initialized');
	});
	require('../../../../').init(app);
	hero.init(app);
};
