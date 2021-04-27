# Pokemon APIs
## Develop

## Build
from the root folder open PowerShell and run the following command to build swagger and cloudformation files
`. "./Deployment-Funcs.ps1"; Build`
a new folder `build-artifacts` will be created
## Deploy
from the root folder open PowerShell and run the following command to deploy/update your API Stack
`. "./Deployment-Funcs.ps1"; Deploy <stack-profile>`
the `stack-profile` is the name of the environment profile file without the `.json` extentions
