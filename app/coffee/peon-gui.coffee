PeonGUI = class

  $html =
    body: $("body")
    projectName: $("#project-name")
    tasks: $("#tasks")
    taskInfo: $("#task-info")
    actionButtons: $("#action-buttons")
    runTask: $("#run-task")
    killTask: $("#kill-task")
    clearConsole: $("#clear-console")
    progressBar: $("#running")
    output: $("#output")
    notice: $("#notice")
    killAll: $("#kill-all")
    flagForce: $("#action-flag-force")
    flagDebug: $("#action-flag-debug")
    flagVerbose: $("#action-flag-verbose")
  running: false

  disableActivity: () ->
    @running = true
    $html.body.addClass('running')
    $html.progressBar.removeClass('hidden')
    $html.tasks.find('a').prop('disabled', true)

  enableActivity: () ->
    @running = false
    $html.body.removeClass('running')
    $html.progressBar.addClass('hidden')
    $html.tasks.find('a').prop('disabled', false)

  updateTaskInfo: (task) ->
    _taskObject = @project.tasks[task]
    o =
      name: _taskObject.name
      info: _taskObject.info
      example: ""
      configurations: ""
      cliArgs: ""
    codeRegex = /\`{1,3}(\s*?.*?)*?\`{1,3}/gi
    codeExample = _taskObject.info.match(codeRegex)
    if codeExample
      codeExample = codeExample[0].replace(/`/gi, '')
    try
      codeExample = JSON.stringify(JSON.parse("{" + codeExample + "}"), null, 4)
      tmplData =
        title: "Show Help Example"
        content: codeExample
      o.example = guiTmpls.accordian(tmplData)
      o.info = _taskObject.info.replace(codeRegex, '')
    catch error
    taskJSON = []
    if _taskObject.config.indexOf('{') > -1
      o.configurations = prettyJSON(_taskObject.config)
      taskJSON = JSON.parse(_taskObject.config)
    else
      o.configurations = guiTmpls.noConfigs({});
      o.cliArgs = '<input type="text" id="task-config" />'

    try

      if Object.keys(taskJSON).length > 1
        if $.inArray(Object.keys(taskJSON), 'options')
          taskJSONlist = Object.keys(taskJSON)
          taskJSONlist.splice(taskJSONlist.indexOf('options'), 1)
        tmplData =
          title: "Select a Configuration"
          options: taskJSONlist
        o.cliArgs = guiTmpls.dropdown(tmplData)
      else if Object.keys(taskJSON).length > 0
        o.cliArgs = ''
    catch error
      console.log error

    $html.taskInfo.html(guiTmpls.taskInfo(o))

  setProject: () ->
    if @running is false
      $html.output.html('')
    if @project
      $html.tasks.html(guiTmpls.taskList({tasks: Object.keys(@project.tasks).sort()}))
      @bindButtons()

  handleSocketOpen: () =>
    $html.body.removeClass('offline').addClass('online')
    @socket.send('connect')
    @socket

  handleSocketMessage: (event) =>
    if event.data
      try
        eventData = JSON.parse(event.data)
      catch error
        eventData =
          action: false
      eventMessage = event.data
      if eventData and eventData.project
        @project =
          name: eventData.project
          port: parseInt(eventData.port, 10)
          tasks: eventData.tasks
        @setProject()
        $html.projectName.html(@project.name)
      else if eventData and eventData.action is 'done'
        @enableActivity()
      if eventMessage.length > 1 and
      eventData.action isnt 'connected' and
      eventData.action isnt 'done'
        tmplData =
          time: new Date().toString().split(' ')[4]
          # We use jQUery to set the message as text and fetch it with the
          # encoded html entities. XSS protection.
          message: jQuery("<div/>").text(eventMessage.replace(/(\[\d+m)/gi, "")).html();

        $html.output.prepend(guiTmpls.outputLog(tmplData))
    else
      console.log event

  handleSocketClose: (e) =>
    $html.notice.removeClass('hidden')

  handleSocketError: (error) =>
    $html.notice.removeClass('hidden')
    console.log(error)

  connect: (wsPort) ->
    @socket = new WebSocket("ws://" + window.location.hostname + ":#{wsPort}", 'echo-protocol')
    @socket.onopen = @handleSocketOpen
    @socket.onmessage = @handleSocketMessage
    @socket.onclose = @handleSocketClose
    @socket.onerror = @handleSocketError
    @socket

  bindButtons: () ->
    that = @
    $html.tasks.on('click', 'a', (e) ->
      e.preventDefault()
      taskName = $(this).data('task')
      $(this).parent('li').siblings().removeClass('active')
      $(this).parent('li').addClass('active')
      that.currentTask =
        name: taskName
        output: ''
      that.updateTaskInfo(taskName)
      $('html,body').scrollTop(0)
    )
    $html.runTask.on('click', (e) ->
      e.preventDefault()
      $taskSelector = $('#task-config')
      if $taskSelector and $taskSelector.val()
        taskSelectorVal = $taskSelector.val()
        that.currentTask.name = "#{that.currentTask.name}:#{taskSelectorVal}"
      # Collect flags.
      cmd = {
        command: 'runTask',
        taskName: that.currentTask.name,
        flags: []
      }
      if ($html.flagForce.prop('checked'))
        cmd.flags.push('f')
      if ($html.flagVerbose.prop('checked'))
        cmd.flags.push('v')
      if ($html.flagDebug.prop('checked'))
        cmd.flags.push('d')

      that.socket.send(JSON.stringify(cmd))
      that.disableActivity()
    )
    $html.killTask.on('click', (e) ->
      e.preventDefault()
      that.enableActivity()
      $html.output.html('')
    )
    $html.clearConsole.on('click', (e) ->
      e.preventDefault()
      $html.output.html('')
    )
    $html.killAll.on('click', (e) ->
      e.preventDefault()
      if confirm("Close Application")
        # @TODO kill websocket/server process
        window.open('','_self','')
        window.close()
    )

  constructor: (wsPort) ->
    @connect(wsPort)

if window then window.PeonGUI = PeonGUI