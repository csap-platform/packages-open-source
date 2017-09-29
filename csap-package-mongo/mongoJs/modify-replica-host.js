//
//
// remove / add / modify of replicats
//



replicaConfig = rs.conf()

//cfg.members = [cfg.members[0] , cfg.members[1], ....]

myArb = replicaConfig.members[2] 

printjson( myArb )

myArb.host = "csap-dev02:29017"

//printjson(cfg)
print("Reconfiguring") ;
rs.reconfig(replicaConfig, {force : true})


print("Updated") ;
replicaConfig = rs.conf() ;
