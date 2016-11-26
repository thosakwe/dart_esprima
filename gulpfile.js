var gulp = require('gulp');
var ts2dart = require('gulp-ts2dart');

gulp.task('build', function () {
    console.log('Transpiling TypeScript sources...');

    gulp.src('src/*.ts')
        .pipe(ts2dart.transpile())
        .pipe(ts2dart.format())
        .pipe(gulp.dest('lib/src'));
});

gulp.task('watch', ['build'], function () {
    gulp.watch('src/*.ts', ['build']);
});

gulp.task('default', ['build']);