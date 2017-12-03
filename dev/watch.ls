import \../src/ls-compile

ls-compile
    ..watch = true
    ..config = import \../compiler.config.ls
    ..build!
