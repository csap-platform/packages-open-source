ver=db.version();
print("Database version::"+ver);
ism = db.isMaster();
//printjson(ism);
print("Is Primary:: "+ ism.ismaster);
print("Is Secondary:: "+ ism.secondary);
if(ism.arbiterOnly){
	print("Is Arbiter:: "+ism.arbiterOnly);
}
rsstat=rs.status();
printjson(rsstat);