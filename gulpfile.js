var gulp = require('gulp');

var coffee = require('gulp-coffee');
var concat = require('gulp-concat');
var karma = require('karma').server;
var uglify = require('gulp-uglifyjs');
var ngAnnotate = require('gulp-ng-annotate');
var runSequence = require('run-sequence');
var del = require('del');

/**
 * Run test once and exit
 */
gulp.task('test', function (done) {
  return karma.start({
    configFile: __dirname + '/karma.conf.js',
    singleRun: true
  }, done);
});

/**
 * Run test continually
 */
gulp.task('test:dev', function (done) {
  return karma.start({
    configFile: __dirname + '/karma.conf.js',
    singleRun: false
  }, done);
});

gulp.task('coffee', function () {
  return gulp.src('./src/*.coffee')
    .pipe(coffee({bare: true}))
    .pipe(gulp.dest('./.tmp/'))
});

gulp.task('concat', function () {
  return gulp.src('.tmp/*.js')
    .pipe(concat('restangular-object-cache.js'))
    .pipe(gulp.dest('./dist/'))
});

gulp.task('compress', function(done) {
  return gulp.src('.tmp/*.js')
    .pipe(ngAnnotate())
    .pipe(uglify('restangular-object-cache.min.js'))
    .pipe(gulp.dest('./dist/'))
});

gulp.task('clean', function() {
  return del(["dist/*",".tmp"])
});

gulp.task('default', function() {
  return runSequence('test','clean','coffee',['concat','compress'])
});
