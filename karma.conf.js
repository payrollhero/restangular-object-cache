// Karma configuration
// http://karma-runner.github.io/0.10/config/configuration-file.html
module.exports = function (config) {
  config.set({
    basePath: '',
    frameworks: ['jasmine'],
    files: [
      'bower_components/angular/angular.js',
      'bower_components/angular-mocks/angular-mocks.js',
      'bower_components/sinonjs/sinon.js',
      'bower_components/underscore/underscore.js',
      'bower_components/underscore.inflection/lib/underscore.inflection.js',
      'bower_components/restangular/dist/restangular.js',
      'bower_components/jquery/dist/jquery.js',
      'bower_components/jasmine-jquery/lib/jasmine-jquery.js',
      'src/*.coffee',
      'spec/test_support.coffee',
      'spec/**.coffee',
      // fixtures
      { pattern:  'spec/fixtures/*.json',
        watched:  true,
        served:   true,
        included: false }
    ],
    exclude: [],
    port: 8080,
    logLevel: config.LOG_INFO,
    autoWatch: true,
    browsers: ['Chrome'],
    frameworks: ['jasmine'],
    plugins: [
      'karma-jasmine',
      'karma-coffee-preprocessor',
      'karma-chrome-launcher'
    ],
    singleRun: false,
    preprocessors: { '**/*.coffee': ['coffee'] }
  });
};
