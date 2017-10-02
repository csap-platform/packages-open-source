
# csap-package-redis

## Provides

builds redis from source, uploads binary as part of package to repository, and defines default configuration for 1-n redis peers.

References: https://redis.io/documentation

## Configuration

Set the following  environment variables to configure redis
```
{
	"redisMaster": "$serviceRef:redis",
	"redisCredential": "$lifeCycleRef:redisCredential"
}
```

Note: upload redis source to your [ tools server](https://github.com/csap-platform/csap-core/tree/master/csap-core-install)