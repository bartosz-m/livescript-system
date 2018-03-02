import
    \../src/system
    \../.compiler.config : config

system
    ..watch = false
    ..clean = true
    ..config = config
    ..build!
