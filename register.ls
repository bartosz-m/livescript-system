require = require("@std/esm")(module, {"cjs":true,"esm":"js"})
require! <[
  assert
  path
  process
  chokidar
  fs-extra
  
  livescript
  livescript/lib/lexer
  \./src/livescript/Compiler
]>

livescript.lexer = lexer

ls-compiler = Compiler.create {livescript}

absolute-path = -> path.normalize path.join process.cwd!, it
{ define-property } = Object

# using symbol just as substitude for non enumerable properties

console.log \registering
require.extensions.'.ls' = (module, filename) ->
    console.log \compiling
    file = fs.read-file-sync filename, 'utf8'
    js = compiler.compile-code file, {filename, +bare, map: "embedded"} .code
    try
        module._compile js, filename
    catch
        throw e


compiler
    ..lib-path = './lib'

    ..src-path = './src/'

    ..default-options =
        map: 'linked'
        bare: false
        header: false
    
    ..compile-ast = (code, options = {}) ->
              ast = livescript.ast code
              output = ast.compile-root options
              output.set-file options.relative-filename
              result = output.to-string-with-source-map!
                  ..ast = ast
    ..[_watching] = true
    ..to-compile = 0
    ..compile-code = (filepath) ->
        @to-compile++
        relative-path = path.relative @src-path, filepath
        try
            ls-code = fs-extra.read-file-sync filepath, \utf8
            options =
                filename: filepath
                relative-filename: path.join \../src relative-path
                output-filename: relative-path.replace /.ls$/ '.js'
            console.log "compiling #relative-path"
            js-result = ls-compiler.compile ls-code, options <<< @default-options
            # js-result = @compile-ast ls-code, options <<< @default-options
            ext = if js-result.ast.exports?length or js-result.ast.imports?length
            then '.mjs'
            else '.js'
            relative-js-path = relative-path.replace '.ls', ext
            output = path.join @lib-path, relative-js-path
            relative-map-file = "#relative-js-path.map"
            map-file = path.join @lib-path, relative-map-file
            js-result
                ..source-map = ..map.to-JSON!
                ..code += "\n//# sourceMappingURL=#relative-map-file\n"
            js-result
        catch
            console.error e.message
            console.log e.stack
        
    ..build = !->
        for plugin in @config.plugins
            plugin.install ls-compiler
        @lib-path = absolute-path @lib-path
        @src-path = absolute-path @src-path
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

