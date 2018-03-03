export default config =
    plugins:
          * plugin: import \livescript-transform-esm/lib/plugin
            config: format: \esm
          * import \livescript-transform-object-create
          * import \livescript-transform-implicit-async
          ...
