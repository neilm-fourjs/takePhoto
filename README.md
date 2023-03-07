# takePhoto
take/choose image on Android device and send that file to a server.

## Goal
The goal was to have a mobile application that can run on an Android device and allow for a photo to be taken or chosen, then it is sent to a server.

The demo consists of two programs, one is the Genero Mobile application, the other is the REST web service.

## Prerequisites
This demo was made with Genero 4.01.

## The Code
The GeneroStudio project has two 'groups', ClientSide and ServerSide

See 'main.4gl' in the ClientSide project node and change the url to be your server.
```
-- This URL is my demo server - Change this to point to your server.
CONSTANT C_URL  = "https://generodemos.dynu.net/g/ws/r/si/storeImage"
```

NOTE: I've only tested the web service on a Linux server.

The Service contains 3 functions.
* saveImg : saves the 'image' file that is POST'd to it into an 'images' folder
* saveLog : saves a file that is POST'd to it into a 'files' folder, intended for applications 'log' file but could save most types of files.
* pause : simply pauses for a specified number of secords - used for timeout testing only

## Service REST openapi
The complete OpenAPI for the service, as deployed to my test server.
```
{
  "openapi": "3.0.0",
  "info": {
    "title": "storeImage",
    "contact": {
      "email": "neilm@4js.com"
    },
    "version": "1.2"
  },
  "servers": [
    {
      "url": "https://generodemos.dynu.net/g/ws/r/si/storeImage"
    }
  ],
  "paths": {
    "/pause/{l_tim}": {
      "get": {
        "description": "Pause for timeout test",
        "operationId": "pause",
        "parameters": [
          {
            "in": "path",
            "name": "l_tim",
            "required": true,
            "schema": {
              "type": "integer",
              "format": "int32"
            }
          }
        ],
        "responses": {
          "200": {
            "description": "Success",
            "content": {
              "application/json": {
                "schema": {
                  "type": "string"
                }
              }
            }
          }
        }
      }
    },
    "/saveImg": {
      "post": {
        "description": "Store an image file",
        "operationId": "saveImg",
        "parameters": [
          {
            "in": "header",
            "name": "X-fileName",
            "description": "File name",
            "required": false,
            "schema": {
              "type": "string"
            }
          }
        ],
        "requestBody": {
          "required": true,
          "content": {
            "image/*": {
              "schema": {
                "type": "string",
                "format": "binary"
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "Success",
            "content": {
              "application/json": {
                "schema": {
                  "type": "string"
                }
              }
            }
          }
        }
      }
    },
    "/saveLog": {
      "post": {
        "description": "Store a file",
        "operationId": "saveLog",
        "parameters": [
          {
            "in": "header",
            "name": "X-fileName",
            "description": "File name",
            "required": false,
            "schema": {
              "type": "string"
            }
          },
          {
            "in": "header",
            "name": "X-type",
            "description": "File type",
            "required": false,
            "schema": {
              "type": "string"
            }
          }
        ],
        "requestBody": {
          "required": true,
          "content": {
            "text/plain": {
              "schema": {
                "type": "string",
                "format": "binary"
              }
            }
          }
        },
        "responses": {
          "200": {
            "description": "Success",
            "content": {
              "application/json": {
                "schema": {
                  "type": "string"
                }
              }
            }
          }
        }
      }
    }
  }
}
```
