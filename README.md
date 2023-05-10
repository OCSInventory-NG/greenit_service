# OCS Inventory Service - Green IT

<p align="center">
  <img src="https://cdn.ocsinventory-ng.org/common/banners/banner660px.png" height=300 width=660 alt="Banner">
</p>

<h1 align="center">Service GreenIT</h1>
<p align="center">
  <b>Some Links :</b><br>
  <a href="https://ask.ocsinventory-ng.org">Ask question</a> |
  <a href="https://www.ocsinventory-ng.org/?utm_source=github-ocs">Website</a> |
  <a href="https://www.ocsinventory-ng.org/en/#ocs-pro-en">OCS Professional</a>
</p>

## Description

Currently supported on Windows, this service is made to retrieve gather power consumption information.

> _**IMPORTANT NOTE : This service is required if you use GreenIT Plugin downloadable <a href="https://github.com/Atineon/ocsinventory-plugin_greenit">here</a>**_

## Prerequisites

> _NOTE : Every agents which have the service installed can return GreenIT data._

- Windows 10

## Installation

To install the service on your agents :

- Download the service <a href="https://github.com/Atineon/ocsinventory-service_greenit/releases/">here</a> to get the executable and start it.

- Go to the config page :

<p align="center">
  <img src="https://i.postimg.cc/VsXYPhJH/Capture-d-cran-du-2023-05-10-11-33-16.png" alt="Config Page"/>
</p>

- Configuration :

  - The period between collecting information is a time in seconds that will allow the service to start colecting information.

    > _Example : if you put it to 5, it will collect information every 5 seconds._

  - The period between upload is a time in minutes that will allow the service to write information collected into the data file _(C:\\ProgramData\GreenIT\data.json)_

    > _NOTE : "C:\\ProgramData" is an unvisible folder._ > _Example : if you put it to 5, it will write information into data file every 5 minutes._

  - The period between saves is a time in hours that will allow the service to create a ".bak" file next to data file to don't lose your last data.

    > _Example : if you put it to 5, it will create/update the backup file every 5 hours._

- Click on install and check start the service at the end. And yes, that's all :-)
