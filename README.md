# OpCon Solution Manager user refresh settings
This script allows you to define consistent OpCon Solution Manager refresh settings, across all/some of your OpCon users.  By default its setup for refresh settings but could be tweaked to change other settings.

Most likely this would be run daily in a production OpCon environment to apply to new users or anyone that changed their settings.

# Prerequisites
* Powershell v5.1+
* OpCon Release 20+

# Instructions
    *[string]$url - https://<opcon server>:<port>/api
    *[string]$opconUser - If user is blank, assumes API token is in the $opconPW variable
    *[string]$opconPW - Encrypted global property or token (with "Token ....")
    *[string]$exclude - List of user loginNames to exclude (comma separated)
    
    All below settings default to 60 (can be changed on execution or in the code)
    *[int]$refreshIntervalAppStatus
    *[int]$refreshIntervalEscalations
    *[int]$refreshIntervalSelfService
    *[int]$refreshIntervalSelfServiceExecution
    *[int]$refreshIntervalSelfServiceExecutions
    *[int]$refreshIntervalAgentsGrid
    *[int]$refreshIntervalSummary
    *[int]$refreshIntervalProcessesGrid
    *[int]$refreshIntervalGraph
    *[int]$refreshIntervalScheduleBuild
    *[int]$refreshIntervalVision
  
Example with refresh settings defined in the script and excluding "ocadm" user:
```
powershell.exe -ExecutionPolicy Bypass -File "C:\OpCon_SetUserRefresh.ps1" -opconUser "test" -opconPW "password" -exclude "ocadm"
```  
# Disclaimer
No Support and No Warranty are provided by SMA Technologies for this project and related material. The use of this project's files is on your own risk.

SMA Technologies assumes no liability for damage caused by the usage of any of the files offered here via this Github repository.

# License
Copyright 2019 SMA Technologies

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

# Contributing
We love contributions, please read our [Contribution Guide](CONTRIBUTING.md) to get started!

# Code of Conduct
[![Contributor Covenant](https://img.shields.io/badge/Contributor%20Covenant-v2.0%20adopted-ff69b4.svg)](code-of-conduct.md)
SMA Technologies has adopted the [Contributor Covenant](CODE_OF_CONDUCT.md) as its Code of Conduct, and we expect project participants to adhere to it. Please read the [full text](CODE_OF_CONDUCT.md) so that you can understand what actions will and will not be tolerated.
