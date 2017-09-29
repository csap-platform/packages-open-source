print( "-\n-\n ============== Events Warmup to load indexes after restart" );

print("\n\n Setting slave ok") ;
rs.slaveOk() ;

db = db.getSiblingDB( "event" );

// limited javascript date support
function dateFormated( daysAgo ) {

	var now = new Date();
	var then = new Date( new Date().setDate( now.getDate() - daysAgo ) )

	// 2016-09-20T18:21:43
	var yyymmdd = then.toISOString().substr( 0, 10 )

	return yyymmdd;
}

var startDate = dateFormated( 28 );
var endDate = dateFormated( 1 );
var today = dateFormated( 0 );

var appIds = db.eventRecords.distinct(
		"appId", {
			'createdOn.date': {
				$gte: startDate,
				$lte: endDate
			}
		} );

print( "Found Appids: ", appIds );
print( "\t\t startDate:", startDate, "\t\t endDate:", endDate );

var allUsers = db.eventRecords.distinct(
		"metaData.uiUser", {
			'createdOn.date': {
				$gte: startDate,
				$lte: endDate
			}
		} );

print( "Found allUsers: ", allUsers.length );

for ( var appIndex = 0; appIndex < appIds.length; appIndex++ ) {

	// count appids
	var appCount = db.eventRecords.count( {
		"createdOn.date": {
			$gte: startDate,
			$lt: endDate
		},
		"appId": appIds[appIndex]
	} );

	print( "-\n-\n ============== Appid: " + appIds[appIndex]
			+ " Document Count: " + appCount );

	var lifes = db.eventRecords.distinct(
			"lifecycle", {
				'createdOn.date': {
					$gte: startDate,
					$lte: endDate
				},
				"appId": appIds[appIndex]
			} );

	// printjson( lifes );

	for ( var lifeIndex = 0; lifeIndex < lifes.length; lifeIndex++ ) {
		// count appids
		var lifeCount = db.eventRecords.count( {
			"createdOn.date": {
				$gte: startDate,
				$lt: endDate
			},
			"appId": appIds[appIndex],
			"lifecycle": lifes[lifeIndex]
		} );

		var users = db.eventRecords.distinct(
				"metaData.uiUser", {
					"createdOn.date": {
						$gte: startDate,
						$lte: endDate
					},
					"appId": appIds[appIndex],
					"lifecycle": lifes[lifeIndex]
				} );

		var categorys = db.eventRecords.distinct(
				"category", {
					"createdOn.date": {
						$gte: startDate,
						$lte: endDate
					},
					"appId": appIds[appIndex],
					"lifecycle": lifes[lifeIndex]
				} );

		var projects = db.eventRecords.distinct(
				"project", {
					"createdOn.date": {
						$gte: startDate,
						$lte: endDate
					},
					"appId": appIds[appIndex],
					"lifecycle": lifes[lifeIndex]
				} );

		print( "\t\t Life: " + lifes[lifeIndex], "\t\t Events: " + lifeCount
				+ "\t\t Users: ", users.length,
				"\t\t categorys: ", categorys.length,
				"\t\t projects: ", projects.length );

		for ( var projIndex = 0; projIndex < projects.length; projIndex++ ) {
			var projectEventCount = db.eventRecords.count( {
				"createdOn.date": {
					$gte: startDate,
					$lt: endDate
				},
				"appId": appIds[appIndex],
				"lifecycle": lifes[lifeIndex],
				"project": projects[projIndex]
			} );
			print( "\t\t appId: ", appIds[appIndex],
					"\t\t lifecycle: " + lifes[lifeIndex],
					"\t\t project: " + projects[projIndex],
					"\t\t projectEventCount: " + projectEventCount );
		}

	}

}

print( "-\n-\n ============== Metrics Warmup to load indexes after restart" );

metricsDb = db.getSiblingDB( "metricsDb" );

var metricsCount = metricsDb.metrics.count( {
	'createdOn.date': {
		$gte: startDate,
		$lte: endDate
	}
} );
//  use run command to get stats for commands
//db.runCommand(
//        {
//            distinct: 'metrics',
//            key: 'attributes.hostName',
//            query: { 'createdOn.date': "2016-09-20" } 
//        } ) ;
var hostNames = metricsDb.metrics.distinct(
		"attributes.hostName", {
			'createdOn.date': today
		} );

print( "Found metrics collection size: ", metricsCount,
		"\t\t unique hosts: ", hostNames.length );

for ( var hostIndex = 0; hostIndex < hostNames.length; hostIndex++ ) {

	if ( hostIndex % 20 !== 0 )
		continue;

	var graphIds = metricsDb.metrics.distinct(
			"attributes.id", {
				"attributes.hostName": hostNames[hostIndex],
				'createdOn.date': today
			} );

	print( "\t\t attributes.hostName: ", hostNames[hostIndex], " unique attributes.id: ", graphIds.length );
}

