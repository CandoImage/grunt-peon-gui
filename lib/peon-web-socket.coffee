class PeonWebSocket
  grunt = require("grunt")
  findup = require('findup-sync')
  child_process = require("child_process")
  path = require("path")
  pkg: require(process.cwd() + '/package.json')
  workers: []
  projectPort: 0
  server: require('http').createServer((request, response) ->
    response.writeHead(404)
    response.end()
  )

  constructor: (grunt) ->
    process.on("uncaughtException", @killWorkers)
    process.on("SIGINT", @killWorkers)
    process.on("SIGTERM", @killWorkers)
    @tasks = grunt.task._tasks
    @grunt = grunt

    # Read the config that runs the GUI and see if there's another base path set
    # to use for the tasks. If not check if grunt was run with the gruntfile
    # option if not, scan the current working directory for the file.
    if @grunt.config.get('gui.options.gruntfile')
      gfp = grunt.config.get('gui.options.gruntfile')
    else if grunt.option('guigruntfile')
      gfp = grunt.option('guigruntfile')
    else if grunt.option('guigruntfolder')
      grunt.log.writeln(
        "Search folder for gruntfile: " + grunt.option('guigruntfolder')
      )
      gfp = findup(
        'Gruntfile.{js,coffee}',
        {
          nocase: true,
          cwd: grunt.option('guigruntfolder')
        }
      )
    else if grunt.option('gruntfile')
      gfp = grunt.option('gruntfile')
    else
      gfp = findup('Gruntfile.{js,coffee}', {nocase: true})

    @gruntFilePath = gfp

    grunt.log.writeln("Use gruntfile: " + gfp)

    @readTasks()
    @removeTasks(['gui'])
    #@addConfigToTasks()

  # @TODO Add support for configuration fetch.
  readTasks: () ->
    #grunt.log.writeln('grunt --help --gruntfile ' + @gruntFilePath)
    outBuffer = child_process.execSync(
      'grunt --help --gruntfile ' + @gruntFilePath
    )
    grunt_config = outBuffer.toString().split("\n")
    tasksArea = false
    pattern = /^\s*([^\s]{1,}?)\s{2}.*[^\*]$/
    @tasks = {}
    that = @
    grunt_config.forEach((value) ->
      if (tasksArea && value.length == 0)
        tasksArea = false

      if (tasksArea)
        # TRIM to ensure we don't have a random number of spaces at the end.
        value = value.replace(/\s+$/, '')
        if ((result = pattern.exec(value)))
          that.tasks[result[1]] = {
            name: result[1],
            info: "",
            config: "No configuration",
          }

      if (value.indexOf('Available tasks') > -1)
        tasksArea = true
    )

  addConfigToTasks: () ->
    config = @grunt.config.get()
    that = @
    grunt.util._.forEach(@tasks, (task, k)->
      taskConfig = JSON.stringify(config[k], null, 4) || "No configuration"
      that.tasks[k].config = taskConfig
    )

  removeTasks: (taskList) ->
    that = @
    grunt.util._.forEach(@tasks, (task, k)->
      if grunt.util._.indexOf(taskList, task.name) > -1
        delete that.tasks[k]
    )

  killWorkers: () ->
    grunt.log.writeln("Shutdown - start cleanup")
    if @workers
      @workers.forEach((worker) ->
        grunt.log.writeln("Kill worker: " + worker.pid)
        process.kill(worker)
      )
    process.exit()

  getSocket: ()->
    @projectPort

  startWorker: ()->
    ps = require('portscanner')
    that = @
    ps.findAPortNotInUse(61750, 61750, 'localhost', (err, port) ->
      that.projectPort = port
      PeonGUIServer = require('../lib/peon-gui-server')
      new PeonGUIServer(that).run()
      if that.projectPort
        that.server.listen(port, () ->
          grunt.log.writeln("WebSocket running on localhost:#{port}")
        )
      else
        grunt.log.writeln("Too many Peon WebSockets open. Close one.")
    )
    @listen()

  listen: () ->
    WebSocketServer = require('websocket').server
    wsServer = new WebSocketServer(
      httpServer: @server
      autoAcceptConnections: false
    )
    that = @
    wsServer.on('request', (request) ->
      connection = request.accept('echo-protocol', request.origin)
      connection.on('message', (message) ->
        if message.type is 'utf8'
          msg = message.utf8Data
          if msg is 'connect'
            connection.sendUTF(JSON.stringify(
              tasks: that.tasks
              project: that.pkg.name
              port: that.projectPort
              action: "connected"
            ))
          else
            # Extract command.
            msg = JSON.parse(msg)
            is_known_task = Object.keys(that.tasks).indexOf(msg.taskName) > -1
            if msg.taskName? && is_known_task
              connection.send("Running Task: #{msg.taskName}")
  #            worker = child_process.spawn(
  #             'grunt --gruntfile ' + that.gruntFilePath,
  #              [msg],
  #              {cwd: path.dirname(that.gruntFilePath)}
  #            )
              flags = ''
              if msg.flags?
                # Ensure flag is safe.
                msg.flags.forEach((flag) ->
                  if ((['d', 'f', 'v']).indexOf(flag) > -1)
                    flags += ' -' + flag
                )

              command ='grunt --gruntfile ' +
                  that.gruntFilePath +
                  flags + ' ' +
                  msg.taskName

              connection.send("Command: #{command}")
              worker = child_process.exec(
                command,
                {
                  cwd: path.dirname(that.gruntFilePath)
                }
              )
              that.workers.push(worker)
              worker.stdout.on('data', (data) ->
                if data
                  connection.send(data.toString())
                  grunt.log.writeln(data.toString())
              )
              worker.stdout.on('end', (data) ->
                connection.sendUTF(JSON.stringify({ action: 'done'}))
              )
              worker.stderr.on('data', (stderr) ->
                grunt.log.writeln stderr
                if stderr then connection.send(stderr.toString())
              )
      )
      connection.on('close', () ->

      )
    )

module.exports = PeonWebSocket
