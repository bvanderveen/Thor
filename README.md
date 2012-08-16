![Thor](http://adronhall.smugmug.com/Software/Software-Development/Pyrocumulus/i-NqSGc4m/0/S/Marvel-vs-Capcom-3-MVC3-S.jpg "Thor")
Project Thor Overview
===
The Thor Project is setup to deliver a high quality, solid user experience, and resilient user interface for Cloud Foundry (w/ Iron Foundry Extension Support) PaaS enabled systems to the Apple OS-X System. This project, to ensure a solid user experience utilizes the Cocoa Framework.

_**Please fork and contribute back.**_ If you'd like to contact the team working on Thor so we can discuss our current road map, please feel free to contact me [Adron Hall](https://github.com/Adron/) via Twitter [@Adron](https://twitter.com/#!/adron) or e-mail me <adron.hall@tier3.com>. You can also of course message me directly via Github.
Technology & Tools Used
---
The tools used to create, build and maintain this project include Xcode. So far there is no other peripheral software used at this time, of course, that is always subject to change.
Technical Description
---
This application uses the [VMC CLI](https://github.com/cloudfoundry/vmc) or  [Iron Foundry VMC CLI for .NET](https://github.com/IronFoundry/vmc) as an underlying tool. The VMC tool acts as an abstraction layer to protect from changes that are made to the underlying cloud controller and other Cloud Foundry architecture.
Workflow
---
The workflow we're using for Thor is viewable via the [Issues](https://github.com/IronFoundry/Thor/issues) section used in conjunction with the [Huboard Kanban](http://huboard.com/IronFoundry/Thor/board).

The Kanban follows a simple backlog (with as minimum of a backlog kept as possible), then that becomes working, and steps through the remaining items as work is completed.

Building the source
---
This project makes use of git submodules. After cloning the repository, change into the root of the repo and run the following command to grab all of the submodules.

    git submodule update --init --recursive

