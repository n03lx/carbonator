# Created by Blake Cornell, CTO, Integris Security LLC
# Integris Security Carbonator - Beta Version - v1.1
# Released under GPL Version 2 license.
# Use at your own risk


#Modified by Krysta Cox for automated NCATS Web Application Assessment purposes

if [[ -n $1 ]] #not provide enough parameters to launch carbonator
then
	DOMAIN=$1

	burpPath="/root/Tools/burp/burpsuite_pro_v1.6.25.jar" #UPDATE this when a new version of burp is installed
	now=$(date +%m%d%Y-%H%M%S)
	#Report and Log directories
	ReportPath="/root/Tools/burp/carbonator/reports/$now"
	mkdir $ReportPath
	nMapReport="$ReportPath/nmap_$now.xml"
	EyeWitnessReport="$ReportPath/eyewitness_targets_$now.txt"
	Log="/root/Tools/burp/carbonator/logs/$now.txt"
	Tmp="/root/Tools/burp/carbonator/logs/output_$now.txt"

	echo "======================+++ AUTOMATED WEB RECON +++======================"
	echo "+++NMAP DISCOVERY+++"
	echo "[*] Launching nmap scan..."
	nmap -sS -p80,443 -oX $ReportPath/nmap_$now.xml $DOMAIN
	echo "[*] nMap complete. Report = $nMapReport"
	
	echo
	echo "+++EYEWITNESS CAPTURE+++"
	echo "[*] Launching eyewitness scan..."	
	echo
	#generate eyewitness report
	python /root/Tools/eyewitness/EyeWitness.py -f $nMapReport -d $ReportPath/EyeWitness_$now &> $Log
	#generate eyewitness target report file to feed to burp
	python /root/Tools/eyewitness/EyeWitness.py -f $nMapReport --createtargets $EyeWitnessReport &> $Log 
	echo "Identified targets:"
	cat $EyeWitnessReport
	echo
	echo "[*] EyeWitness completed. Report = $EyeWitnessReport"

	#deliminate target output to import into burp scanner command line arguments
	while IFS=':' read A B C;do
    		echo "$A ${B:2} $C" >> $Tmp
	done < $EyeWitnessReport

	echo
	echo "+++BURP SPIDER & SCAN+++"
	echo "[*] Launching burp scan..."
	echo
	echo "This scan runs in the background and may take awhile. Be patient."
	cat $Tmp | xargs -L1 java -jar -Xmx1024m -Djava.awt.headless=true $burpPath
	echo "[*] Burp completed."
	echo
	echo "DONE. Reports stored in $ReportPath"

	#cleanup
	rm $Tmp

	#Text message alert when burp scan is complete
	if [[ -n $2 ]]
	then
		PHONE=$2
		curl http://textbelt.com/text -d number=$PHONE -d "message=Recon completed." &> /dev/null
	fi

else
	echo "Usage: $0 domain phone#"
	echo '    'Example: $0 localhost 5555555555
fi

exit
