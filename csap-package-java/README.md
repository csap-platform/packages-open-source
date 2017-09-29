
# csap-package-java

## Provides
jdk installation and configuration. Support jdk 8 (default) and jdk 9. Older jdks can be quickly added if needed (open an  issue)

References: [Java 9](https://docs.oracle.com/javase/9/),  [Java 8] (https://docs.oracle.com/javase/8/)

## Configuration

Set the following  environment variables to select jdk
```
{
	"jdkMajorVersion": "jdk9", // jdk8 is the default 
	"jdkMinorVersion": "none"  // 141 is the default
}
```

Note: upload binaries to your [ tools server](https://github.com/csap-platform/csap-core/tree/master/csap-core-install)