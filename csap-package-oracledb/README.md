
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
 file to the oracle service [property overrides](https://github.com/csap-platform/csap-core/wiki/Application-Definition)

- add your company - it will be updated in corresponding oracle files: ldap.ora, tnsnames.ora,sqlnet.ora
```
	"environmentVariables": {
		"companyDomain": "yourcompany"
	}
	
```

Note: upload mongo binary to your [ tools server](https://github.com/csap-platform/csap-core/tree/master/csap-core-install)

