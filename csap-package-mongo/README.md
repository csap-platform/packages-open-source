
# csap-package-mongo

## Provides

Downloads/installs mongo binaries, along with configuration and setup. 
Configuration is optimized for the [CSAP Event Service](https://github.com/csap-platform/csap-event-services),
but likely can be used as is for moderate storage.

References: https://docs.mongodb.com/manual/

## Configuration

recommended: set service configuration attributes to: ```isDataStore,killWarnings```

Set the following  environment variables to select jdk
```
{
	"mongoUser": "$lifeCycleRef:mongoUser",
	"mongoPassword": "doDecode:$lifeCycleRef:mongoPassword",
	"mongoVersion": "mongodb-linux-x86_64-rhel70-3.4.6",
	"mongoData": "/data/event34/data/db",
	"IsMaster": "$application:IsMaster",
	"lifecycle": {
		"dev": {
			"mongoVersion": "mongodb-linux-x86_64-rhel70-3.4.6"
		}
	}
}
```

Note: upload mongo binary to your [ tools server](https://github.com/csap-platform/csap-core/tree/master/csap-core-install)

