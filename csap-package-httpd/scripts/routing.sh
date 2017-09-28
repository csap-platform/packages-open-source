#!/bin/bash


function printIt() { echo; echo; echo =========; echo == $* ; echo =========; }

printIt "iptables rules filtered with 8080"
iptables --table nat -L --line-number | grep 8080

lineNumbers=`iptables --table nat -L --line-number | grep 8080 | awk '{ print $1}' | tac`

# for i in $( rulesWith8080 | tac ); do
for lineNumber in $lineNumbers ; do 
	printIt "Deleting rule with line number: $lineNumber"
	iptables -t nat -D PREROUTING $lineNumber; 
done



primaryNetworkDevice=`route | grep default | awk '{ print $8}'`
	
printIt adding new rule mapping 80 to 8080 on $primaryNetworkDevice
iptables -t nat -A PREROUTING -i $primaryNetworkDevice -p tcp --dport 80 -j REDIRECT --to-port 8080
