import \../src/system

system
    ..watch = false
    ..config = import \../.compiler.config.ls
    ..build!
