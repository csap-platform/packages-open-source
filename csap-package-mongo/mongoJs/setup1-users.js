//
//  After an OS wipe - clean mongo install - user is added, then replication configured to sync schema and indexes
//      - setup2-csap-db.js is only needed if wanting to create from scratch
//


db = connect("localhost:27017/admin");
//This is required as data and analytics project uses old authentication schmea
db.system.version.insert({ "_id" : "authSchema", "currentVersion" : 3 });
db.createUser({user: "dataBaseReadWriteUser",pwd: "password",roles: [{ role: "readWriteAnyDatabase", db: "admin" },{ role:"clusterAdmin", db: "admin" },{role: "userAdminAnyDatabase",db: "admin"}]})
db.auth("dataBaseReadWriteUser","password");