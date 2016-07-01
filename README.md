# grunt-peon-gui
![Peon](https://raw.github.com/voceconnect/grunt-peon-gui/master/app/assets/img/screen.png)

> Run a local web GUI for Grunt tasks

## Getting Started
This plugin requires Grunt `~0.4.0`

If you haven't used [Grunt](http://gruntjs.com/) before, be sure to check out the [Getting Started](http://gruntjs.com/getting-started) guide, as it explains how to create a [Gruntfile](http://gruntjs.com/sample-gruntfile) as well as install and use Grunt plugins. Once you're familiar with that process, you may install this plugin with this command:

```shell
npm install grunt-peon-gui --save-dev
```

Once the plugin has been installed, it may be enabled inside your Gruntfile with this line of JavaScript:

```js
grunt.loadNpmTasks('grunt-peon-gui');
```

## GUI task
_Run this task with the `grunt gui` command._

## Use another gruntfile
You can install the GUI in a dedicated directory and run another gruntfile using
three ways:

 1. Pass the command line argument `--guigruntfile=/path/to/file/Gruntfile.js`
 2. Pass the command line argument `--guigruntfolder=/path/to/file/` - searches for Gruntfile.js / Gruntfile.coffee
 3. Add configuration to the gruntfile: 
 
    ```js
     gui:
       options:
         gruntfile: '/path/to/file/Gruntfile.js'
    ```

## Release History
 * 2016-07-01 - v1.0.x - Enable the usage of another grunt file for execution.
 * 2014-02-00 - v1.0.1 - Bugfix for passing CLI args.
 * 2013-11-01 - v1.0.0 - Update to Bootstrap v3. New theme. Support for CoffeeScript gruntfiles.
 * 2013-10-31 - v0.5.0 - Cleanup.
 * 2013-07-15 - v0.4.0 - Use gruntfile from grunt object.
 * 2013-03-24 - v0.3.0 - Launch browser on task start. Can run completely offline. Style updates.
 * 2013-03-22 - v0.2.0 - App now in CoffeeScript.
 * 2013-03-21 - v0.1.0 - Initial release.

---

Task submitted by [Mark Parolisi](http://github.com/markparolisi)
