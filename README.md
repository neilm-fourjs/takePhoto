# takePhoto
take/choose image on Android device and send that file to a server.

## Goal
The goal was to have a mobile application that can run on an Android device and allow for a photo to be taken or chosen, then it is sent to a server.
The demo consists of two programs, one is the Genero Mobile application, the other is the REST web service.

## Prerequisites
This demo made with Genero 4.01.

## The Code
The GeneroStudio project has two 'groups', ClientSide and ServerSide

See 'main.4gl' in the ClientSide project node and change the url to be your server.
```
-- This URL is my demo server - Change this to point to your server.
CONSTANT C_URL  = "https://generodemos.dynu.net/g/ws/r/si/storeImage"
```

NOTE: I've only tested the web service on a Linux server.
