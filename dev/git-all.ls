import
    \fs
    \child_process : {exec-sync}


options = cwd: process.cwd!



Git = (options = options) ->
    let @ = ((cmd='') -> (exec-sync "git #{cmd}", options) .to-string!trim!)
        @
            ..remotes = (~> @remote!split '\n')
            ..remote = let @ = ((cmd='') ~> @ "remote #{cmd}" .to-string!trim!)
                @
                  ..add = (name, url) ~> @ "add #{name} #{url}"
                  ..get-url = (name) ~> @ "get-url #{name}"
                  ..add-push-url = (name, ...urls) ~>
                      for url in urls 
                          try
                              console.log name, url
                              @ "set-url --add --push #{name} #{url}"
                          catch
                              console.error e 
git = Git!
remotes = git.remotes!
unless remotes.length > 1
    throw Error "This script should be run after there are atleast two remotes"
    
origin = if \origin in remotes then \origin else remotes.0
origin-url = git.remote.get-url origin
all-remote = \all
unless all-remote in remotes
    console.log "adding #{all-remote} #{origin-url}"
    git.remote.add all-remote, origin-url
    
    for remote in remotes when remote != all-remote
        remote-url = git.remote.get-url remote
        console.log git.remote.add-push-url all-remote, remote-url
else
    console.log  "Thre is already remote named #{all-remote}"

