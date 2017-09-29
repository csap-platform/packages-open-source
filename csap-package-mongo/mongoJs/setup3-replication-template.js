//
//  This template is updated using updateReplicationScript.sh
//


var x = rs.initiate(
	{ _id:'rs0',
	  members:[
		MONGOREPLCONFIG
	  ]
	}
);
printjson(x);
print('waiting for set to initiate...');
while( 1 ) {
	sleep(2000);
	x = db.isMaster();
	printjson(x);
	if( x.ismaster || x.secondary ) {
		print("ok, this member is online now; that doesn't mean all members are ");
		print("ready yet though.");
		break;
	}
}