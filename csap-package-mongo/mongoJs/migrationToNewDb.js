
db = db.getSiblingDB("metricsDb");
printjson(db.stats());
quit();

printjson(db.getCollectionNames());

quit();

//
// Sample data migration 70k - 5 mintues? 20% CPU
// alternate hostName match "attributes.hostName":{ $regex: /csap/i } - much slower

print("\n\n =============== Starting Script") ;
db = db.getSiblingDB("metricsDb");


var numberDone = 0;

var hosts = new Array();
for (var i = 21; i < 35; i++) {
	hosts.push( "v01app-prd0" + i ) ; 
}


for (var i = 0; i < hosts.length; i++) {

    curHost = hosts[i];
    var filter = {
        "attributes.hostName" : curHost,
        "createdOn.date" : {
            $lte : "2016-06-01"
        }
    }
    
    print("\n\n Using Filter:");
    printjson( filter ) ;

    numberDone = 0;
    numToDo = db.metricsOld.find(filter).count();

    print("number records to transfer: " + numToDo + " host: " + curHost);

    continue ;
    

    db.metricsOld.find(filter).forEach(
            function(x) {
                db.metrics.insert(x);
                numberDone++;
                if (numberDone % 500 == 0) {
                    print("\n\n === " + numberDone + " of " + numToDo
                            + " host: " + curHost);
                }

            });
}


quit();

quit();

rs.slaveOk();
dbnames = db.getMongo().getDBNames();
// print('DB names ::'+dbnames);
for (var j = 0; j < dbnames.length; j++) {
	db = db.getSiblingDB(dbnames[j]);
	// print('Data base stats for '+dbnames[j])
	printjson(db.stats());
	x = db.getCollectionNames();
	for (var i = 0; i < x.length; i++) {
		col = db.getCollection(x[i]);
		printjson(col.stats());
	}
	print('#########################################################################')
}

quit();
