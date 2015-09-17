module.exports = (grunt) ->
  grunt.loadNpmTasks 'grunt-mocha-test'
  grunt.initConfig
    mochaTest:
      test:
        options:
          reporter: 'spec'
          require: 'coffee-script/register'
          quiet: false
        src: ['test/**/*.coffee']
  grunt.registerTask 'default', 'mochaTest'
