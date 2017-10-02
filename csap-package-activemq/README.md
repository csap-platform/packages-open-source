
# csap-package-activemq

## Provides

- support for activemq, running under a separate user account (mqUser)
	- refer to [csap-core-install](https://github.com/csap-platform/csap-core/tree/master/csap-core-install)
	for notes on creating the mqUser disk and account 


References: http://activemq.apache.org/

## Configuration

- Performance Data below provides a starting point, simply paste into service definition


```
{
	"TotalVmCpu": {
		"mbean": "java.lang:type=OperatingSystem",
		"attribute": "SystemCpuLoad"
	},
	"ProcessCpu": {
		"mbean": "java.lang:type=OperatingSystem",
		"attribute": "ProcessCpuLoad"
	},
	"jmxHeartbeatMs": {
		"mbean": "org.apache.activemq:type=Broker,brokerName=localhost",
		"attribute": "TotalConsumerCount",
		"title": "Health Check (ms)"
	},
	"TotalConsumerCount": {
		"mbean": "org.apache.activemq:type=Broker,brokerName=localhost",
		"attribute": "TotalConsumerCount"
	},
	"JvmThreadCount": {
		"mbean": "java.lang:type=Threading",
		"attribute": "ThreadCount"
	},
	"CsapReferenceQ": {
		"mbean": "org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=csap-test-$host",
		"attribute": "QueueSize"
	},
	"CsapRefmaxTime": {
		"mbean": "org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=csap-test-$host",
		"attribute": "MaxEnqueueTime"
	},
	"CsapRefAdded": {
		"mbean": "org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=csap-test-$host",
		"attribute": "EnqueueCount",
		"delta": "delta"
	},
	"CsapRefDispatched": {
		"mbean": "org.apache.activemq:type=Broker,brokerName=localhost,destinationType=Queue,destinationName=csap-test-$host",
		"attribute": "DequeueCount",
		"delta": "delta"
	}
}
	
```

Note: upload activemq releases to your [ tools server](https://github.com/csap-platform/csap-core/tree/master/csap-core-install)