# Repo download artifacts

Check and download the last artifact from some repository.

Keep the applications that you need to download from a repo up to date easily with this tool

### Usage sample

#### Github Releases

```sh
repo-download-asset add -u "https://github.com/Dracks/repo-download-asset" -n repo-downloads -r ".*x86_64"
```

#### Workflow artifact

To add some workflow artifact you should run the following line
```sh
repo-download-asset add -u "https://github.com/jpochyla/psst" -n psst -r "^.*-gui$" -t artifact
```

Keep in mind that you will need a token to download workflows artifacts, and you should set the token like that:

```sh
repo-download-asset config -github_token <YOUR GITHUB_TOKEN>
```
