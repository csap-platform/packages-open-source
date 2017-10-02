
# csap-package-oracle

## Provides

- support for docker-latest on centos and other redhat based distributions. Other OSs can be added on request

- integrated into csap-core-service:
	- csap file explorer: support for browsing docker container file systems
	- csap application editor: support for specifying image to pull and container configuration and deployment
	- csap host dashboard: adhoc pulls of images, container, creates, ...

References: https://docs.docker.com/

## Configuration

- add [ocm.rsp](https://community.oracle.com/thread/3954068)
 file to your service properties 


```
	"environmentVariables": {
		"replaceCompany": "yourcompany",
		"allowRemote": "true",
		"dockerPackage": "docker-latest"
	}
	
```