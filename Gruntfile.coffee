#global module:false
module.exports = (grunt)->

  SOURCE_DIR = "src/"
  TEST_SOURCE_DIR = "test/"
  BUILD_DIR = "build/"
  TEST_BUILD_DIR = "build_test/"

  COFFEE_FILES = "#{SOURCE_DIR}**/*.coffee"
  SLIM_FILES = "#{SOURCE_DIR}**/*.slim"
  SASS_FILES = "#{SOURCE_DIR}**/*.scss"

  TEST_COFFEE_FILES = "#{TEST_SOURCE_DIR}**/*.coffee"
  TEST_SLIM_FILES = "#{TEST_SOURCE_DIR}**/*.slim"
  TEST_SASS_FILES = "#{TEST_SOURCE_DIR}**/*.scss"


  #
  # extToTask:object
  # ======================
  #
  # Hash that maps file extension to grunt task specific config.
  # `taskFor()` merges this configuration with shared
  # configuration to create the final grunt task config.
  #
  extToTask =
    coffee:
      task: "coffee"
      config:
        ext: ".js"
        options:
          bare: true
          sourceMap: true

    scss:
      task: "sass"
      config:
        ext: ".css"
        options:
          sourcemap: true

    slim:
      task: "slim"
      config:
        ext: ".html"
        options:
          pretty: true

  getFileInfo = (filepath)->
    filepaths: filepaths = if Array.isArray(filepath) then filepath else [filepath]
    isTest: /^test\//.test filepaths[0]
    fileExt: fileExt = /\.(\w+)$/.exec(filepaths[0])[1]
    taskConfig: extToTask[fileExt]

  #
  # taskFor(filepath):{task,config}
  # ============================================
  #
  # Unifies grunt task configuration for coffee, sass, and slim files.
  # This consolidates the logic of merging shared configuration (expand, cwd,
  # src, and dest) with task specific configuration (see `extToTask`).
  #
  # Based on the `filepath`, the proper configuration can be determined.
  # Here is an example return value with brief explanation of how each property
  # value is determined:
  #
  #     {
  #       task: # Based on `filepath`"s extension and whether it"s a test file
  #             # or not (base directory is "src/" or "test/"). See `extToTask`
  #             # for extension to task mapping.
  #             # ex. src/one.coffee -> ["coffee","build"]
  #             # ex. test/one.coffee -> ["coffee","test_build"]
  #             # ex. src/a.slim -> ["slim","build"]
  #
  #       # Grunt task config
  #       config: {
  #
  #         ... # Mixed in task specific properties from `extToTask`
  #
  #         expand: # true. Do NOT concatenated into one file
  #
  #         cwd: # "src/" or "test/" based on the `filepath` base directory
  #
  #         src: # Modified `filepath`, with base directory removed.
  #              # ex. src/one.coffee -> one.coffee
  #
  #         dest: # "build/" or "test_build/" based on the `filepath` base directory.
  #       }
  #     }
  #
  taskFor = (filepath)->
    {filepaths,isTest,fileExt,taskConfig} = getFileInfo filepath

    if taskConfig
      config =
        expand: true
        cwd: cwd = if isTest then TEST_SOURCE_DIR else SOURCE_DIR
        src: filepaths.map (path)-> path.replace new RegExp("^#{cwd}"), ""
        dest: if isTest then TEST_BUILD_DIR else BUILD_DIR

      # Mixin task specific properties
      Object.keys(taskConfig.config).forEach (key)->
        config[key] = taskConfig.config[key]

      task: [
        taskConfig.task
        (if isTest then "test_build" else "build")
      ]
      config: config


  #
  # watchTaskFor(filepath):{task,config}
  # ====================================
  #
  # Unifies grunt watch task configuration for coffee, sass, and slim files.
  #
  # Proper configuration determined by `filepath` (filefile extension).
  # Here is an example return value with brief explanation of how each property
  # value is determined:
  #
  #     # Grunt task config
  #     {
  #         files: # `filepath`
  #         tasks: # "#{task by file extension}:#{"build" or "test_build"}"
  #         options: {
  #           spawn: # false. Do NOT spawn a new process for each compile. Makes
  #                  # compiles much faster.
  #         }
  #     }
  #
  watchTaskFor = (filepath)->
    {filepaths,isTest,fileExt,taskConfig} = getFileInfo filepath

    files: filepaths
    tasks: [
      "#{taskConfig.task}:#{isTest and "test_build" or "build"}"
      "lr-reload"
    ]
    options:
      spawn: false


  grunt.initConfig

    # Metadata
    # ========
    pkg: grunt.file.readJSON "package.json"

    #
    # Compile Tasks for *.coffee, *.scss, and *.slim
    # ==============================================
    #
    # 2 Tasks for each compile type for source and test files
    #
    coffee:
      build: taskFor( COFFEE_FILES ).config
      test_build: taskFor( TEST_COFFEE_FILES ).config

    sass:
      build: taskFor( SASS_FILES ).config
      test_build: taskFor( TEST_SASS_FILES ).config

    slim:
      build: taskFor( SLIM_FILES ).config
      test_build: taskFor( TEST_SLIM_FILES ).config

    copy:
      icons:
        expand: true
        cwd: SOURCE_DIR
        src: "icons/**/*"
        dest: BUILD_DIR

    watch:
      # Source Watch Tasks
      # ==================
      coffee: watchTaskFor COFFEE_FILES
      sass: watchTaskFor SASS_FILES
      slim: watchTaskFor SLIM_FILES

      # Test Watch Tasks
      # ================
      test_coffee: watchTaskFor TEST_COFFEE_FILES
      test_sass: watchTaskFor TEST_SASS_FILES
      test_slim: watchTaskFor TEST_SLIM_FILES

    # Test Task
    # =========
    karma:

      # One time test run on major browsers in parallel
      # Eventually CI build
      unit:
        options:
          configFile: 'test/karma.conf.coffee'
          singleRun: true
          browsers: ['Chrome','Safari','Firefox']

      # Continous/livereload test run for development
      unit_dev:
        options:
          configFile: 'test/karma.conf.coffee'
          autoWatch: true
          singleRun: false
          browsers: ['Chrome']

    # Server Task
    # ===========
    connect:
      server:
        options:
          hostname: "*"
          port: 8000
          base: "./"

  # Only compile the changed file.
  # The task used compiled the changed file is determined by the
  # changed file's extension.
  grunt.event.on 'watch', (action, filepath)->
    if taskConfig = taskFor filepath
      # Tell the compile task which file to compile
      grunt.config taskConfig.task, taskConfig.config

      # Tell LiveReload server which file to reload (the compiled file)
      grunt.config "lr-reload",
        filepath: filepath
                    .replace(/\.\w+$/, taskConfig.config.ext)
                    .replace(/^(src|test)\//, taskConfig.config.dest)

  grunt.loadNpmTasks npmTask for npmTask in [
    "grunt-contrib-coffee"
    "grunt-contrib-sass"
    "grunt-contrib-watch"
    "grunt-contrib-connect"
    "grunt-contrib-copy"
    #"grunt-karma"
    "grunt-slim"
  ]

  grunt.loadTasks "tasks/"

  grunt.registerTask "server", ["connect:server:keepalive"]

  grunt.registerTask "dev", ["default","lr-start","watch"]
  grunt.registerTask "dev-test", ["karma:unit_dev"]

  grunt.registerTask "test", ["karma:unit"]

  grunt.registerTask "default", [
    "copy"
    "coffee:build"
    "sass:build"
    "slim:build"
    "coffee:test_build"
    "sass:test_build"
    "slim:test_build"
  ]


