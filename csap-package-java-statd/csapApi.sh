#!/bin/bash



function displayHeader() {
	echo
	echo
	echo	
	echo ====================================================================
	echo == 
	echo "== CSAP jstatsd package: $*"
	echo ==
	echo ====================================================================
	
}


function printIt() {
	echo;echo;
	echo = 
	echo = $*
	echo = 
}



function buildAdditionalPackages() { displayHeader "No Source Packages" }


function getAdditionalBinaryPackages() { displayHeader "No Binary Packages" }




function killWrapper() {

	
	displayHeader KILL 
	printIt removing jstad policy in $HOME
	
	\rm -rf $HOME/.jstatd.all.policy
	
	# default kill is used from csap-kill.sh
	
}


function stopWrapper() { displayHeader "no stop command" }



function startWrapper() {
	displayHeader START

	cd $csapWorkingDir ;
	
	
	policy=${HOME}/.jstatd.all.policy
	
	# Do not mess with spacing - use for runtime policy file
[ -r ${policy} ] || cat >${policy} <<'POLICY'
grant codebase "file:${java.home}/../lib/tools.jar" {
permission java.security.AllPermission;
};
POLICY
	
	# launch jstatd
	jstatd -J-Djava.security.policy=${policy} &
    

	
}
