# Repo download artifacts

Check and download the last artifact from some repository.

Keep the applications that you need to download from a repo up to date easily with this tool

### Usage sample
```
v run . add -u "https://github.com/jpochyla/psst" -n psst -r "^.*-gui$"
```

### Todo
* Add
    * When a new app is added, check before saving it in the DB if it works fine (run the update-stuff process)
    * Add a parameter to change the type of the app [GithubRepo/GithubRelease]
* 