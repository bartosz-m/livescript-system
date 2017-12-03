require('livescript')
require('livescript-transform-esm/register-cjs')
var lsCompiler = require ('../lib/ls-compile')
lsCompiler.watch = false
lsCompiler.config = require ('../compiler.config.ls')
lsCompiler.build()
