
print("\n\n Setting slave ok") ;
rs.slaveOk() ;


print("\n\n First 2 records in a date range") ;
printjson( db.eventRecords.find({"createdOn.date":{$gte:"2016-03-02",$lt:"2016-03-03"}}).limit(2).toArray() );


print("\n\n Exiting") ;
quit() ;


print("\n\n First 5 records starting with /csap" ) ;
printjson(
	db.eventRecords.find({ 
	    category: { $regex: /^\/csap\/ui/ }, 
	    "metaData.uiUser": "pnightin", 
	    "createdOn.date": { $gte: "2016-04-04", $lt: "2016-04-12" }
	    })
	 .limit(5)
	.toArray()
) ;


print("\n\n Explain plan for query" ) ;

printjson( db.eventRecords
	.find({ 
	    category: { $regex: /^\/csap\/ui/ }, 
	    "metaData.uiUser": "pnightin", 
	    "createdOn.date": { $gte: "2016-04-04", $lt: "2016-04-12" }
	    })
	.explain("executionStats")
) ;





print("\n\n Trending query" ) ;

printjson( db.eventRecords
	.find({ 
	    category: { $regex: /^\/csap\/ui/ }, 
	    "metaData.uiUser": "pnightin", 
	    "createdOn.date": { $gte: "2016-04-04", $lt: "2016-04-12" }
	    })
	.explain("executionStats")
) ;




