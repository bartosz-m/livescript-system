require! \../src/system

system
    ..watch = false
    ..clean = true
    ..config = require \../.compiler.config.ls
    ..build!
