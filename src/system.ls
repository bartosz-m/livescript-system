import <[
  assert
  path
  process
  chokidar
  fs-extra
  
  livescript
  livescript/lib/lexer
  livescript-compiler/lib/livescript/Compiler
]>

livescript.lexer = lexer

default-plugins = [
    import \livescript-transform-esm/lib/plugin
]

# runtime-compiler = Compiler.create {livescript}
# runtime-compiler.install!
for plugin in default-plugins
    plugin.install!

Compiler-compile = Compiler.compile
Compiler-generate-ast = Compiler.generate-ast
Compiler.generate-ast = ->
    ast = Compiler-generate-ast ...
    # console.log ast
    ast
    
Compiler.compile = (code) ->
    
    result = Compiler-compile.apply @,  &
    # console.log \code result
    result

ls-compiler = Compiler.create {livescript}

absolute-path = -> path.normalize path.join process.cwd!, it
{ define-property } = Object

# using symbol just as substitude for non enumerable properties
_watching = Symbol \watching

find-config = (filepath) ->>
    result = null
    current = path.dirname filepath
    directory = path.dirname current
    until result or (current == directory)
        files = await fs-extra.readdir current
        config = files.filter (.match /compiler\.config/)
        if config.length
            result = path.join current, config.0
        current = directory
        directory = path.dirname current
    result

export default compiler = {}
compiler
    ..lib-path = './lib'
    ..src-path = './src/'
    ..compilers = {}
    ..get-compiler = (config-path) ->>
          # console.log \comiler config-path
          unless config-path
              ls-compiler
          else
              config = await async import config-path
              @compilers[config-path] = ls-compiler.copy!
                  ..configure = (config = {}) !-> @install-plugins config.plugins
                  ..install-plugin = (plugin) !->
                      @[]plugins.push plugin
                  ..install-plugins = (plugins) !->
                      unless plugins => return
                      if plugins.length
                          for plugin in plugins
                              if plugin.plugin                    
                                  plugin.plugin.install @, plugin.config
                                  @install-plugin plugin.plugin
                              else
                                  plugin.install @
                                  @install-plugin plugin
                      else
                          for name, plugin-entry of plugins
                              plugin-entry.plugin?install @, plugin-entry.config
                              @install-plugin plugin-entry.plugin
                  
                  ..configure config
              
    ..default-options =
        map: 'linked'
        bare: false
        header: false
        
    ..install-plugins = (plugins) !->
        console.log 'installing plugins'
        unless plugins => return
        if plugins.length
            for plugin in plugins
                if plugin.plugin                    
                    plugin.plugin.install @runtime-compiler, plugin.config
                else
                    plugin.install @runtime-compiler
        else
            for name, plugin-entry of plugins
                plugin-entry.plugin?install @runtime-compiler, plugin-entry.config
    
    ..compile-ast = (code, options = {}) ->
              ast = livescript.ast code
              output = ast.compile-root options
              output.set-file options.relative-filename
              result = output.to-string-with-source-map!
                  ..ast = ast
    ..[_watching] = true
    ..to-compile = 0
    ..compile-code = (filepath) !->>        
        @to-compile++
        relative-path = path.relative @src-path, filepath
        try   
            [ls-code,compiler] = await Promise.all [
                fs-extra.read-file filepath, \utf8
                find-config filepath .then @~get-compiler
            ]
            options =
                filename: filepath
                relative-filename: path.join \../src relative-path
                output-filename: relative-path.replace /.ls$/ '.js'
            console.log "compiling #relative-path"
            js-result = compiler.compile ls-code, options <<< @default-options
            ext = if js-result.is-module then '.mjs' else '.js'
            relative-js-path = relative-path.replace '.ls', ext
            output = path.join @lib-path, relative-js-path
            relative-map-file = "#relative-js-path.map"
            map-file = path.join @lib-path, relative-map-file
            fs-extra.output-file output, js-result.code
            fs-extra.output-file map-file, JSON.stringify js-result.map.to-JSON!
        catch
            if e.stack
                console.error e.stack
            else
                console.error e
            # console.log e.stack
        @to-compile--
        @watch = @[_watching]
        
    ..build = !->
        @runtime-compiler = Compiler.create {livescript}
        @runtime-compiler.install!
        @install-plugins @config.plugins
        @lib-path = absolute-path @lib-path
        @src-path = absolute-path @src-path
        if @clean
        and not (@lib-path in [ '/' '/home' process.cwd! ])
            console.log \cleaning: @lib-path
            fs-extra.remove @lib-path
        console.log \watching "#{@src-path}**/*.ls"
        @watcher = chokidar.watch "#{@src-path}**/*.ls", ignored: /(^|[\/\\])\../
            ..ready = false
            ..on \ready (event, filepath) ~>
                console.log 'initiall scan completed'
                @watcher.ready = true
            ..on \change @~compile-code
            ..on \add @~compile-code
            ..on \unlink (filepath) ~>
                relative-path = path.relative @src-path, filepath
                js-file = path.join @lib-path, (relative-path.replace '.ls', '.js')
                map-file = js-file + \.map
                fs-extra.remove js-file
                fs-extra.remove map-file
    
    define-property .., \watch,
        get: -> @[_watching]
        set: ->
            @[_watching] = it
            if @watcher?ready and @to-compile == 0 and not @[_watching]
                @watcher.close!

