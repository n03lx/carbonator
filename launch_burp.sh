# Created by Blake Cornell, CTO, Integris Security LLC
# Integris Security Carbonator - Beta Version - v1.1
# Released under GPL Version 2 license.
# Use at your own risk

#Modified by n03lx
if [[ -n $1 ]] #not provide enough parameters to launch carbonator
then
	DOMAIN=$1

	burpPath="/root/Tools/burp/burpsuite_pro_v1.6.27.jar" #UPDATE this when a new version of burp is installed
	now=$(date +%m%d%Y-%H%M%S)
	#Report and Log directories
	ReportPath="/root/Tools/burp/carbonator/reports/$now"
	mkdir $ReportPath
	whoisReport="$ReportPath/whois.txt"
	nMapReport="$ReportPath/nmap.xml"
	nMapUrls="$ReportPath/nmapurl.txt"
	EyeWitnessReport="$ReportPath/eyewitness_targets.txt"
	HostList="hostlist_$now.txt"
	Tmp="output_$now.txt"

	starttime=$(date +"%s")

	echo "======================+++ AUTOMATED WEB RECON +++======================"
	#dependencies
	if ! which xmlstarlet  > /dev/null
	then
		echo "[*] Installing Dependencies..." >&1
		apt-get install xmlstarlet
	fi

	echo "+++NMAP DISCOVERY+++"
	echo "[*] Launching nmap scan..."
	nmap -sS -p80,443 --script "whois-*" -oX $nMapReport $DOMAIN > $whoisReport #for less intenstive scan remove '--script dns-brute'
	echo "[*] nMap complete. Report = file://$whoisReport"
	
	#parse XML nmap to include subdomains
	xmlstarlet sel -T -t -m "//host/hostnames/hostname" -v @name -n $nMapReport >> $nMapUrls
	xmlstarlet sel -T -t -v "//host/hostscript/script/table/table/elem[@key='hostname']" -n $nMapReport >> $nMapUrls
	
	echo
	echo "+++EYEWITNESS CAPTURE+++"
	echo "[*] Launching eyewitness scan..."	
	#generate eyewitness report	
	python /root/Tools/EyeWitness/EyeWitness.py -f $nMapUrls -d $ReportPath/EyeWitness --threads 3 --headless --no-prompt > $EyeWitnessReport
	echo "[*] EyeWitness completed. Report = file://$ReportPath/EyeWitness/report.html"

	#build file to input into Burp
	cat $EyeWitnessReport | sed -n -e 's/^.*\(http\)/\1/p' | grep $DOMAIN > $Tmp

	#deliminate target output to import into burp scanner command line arguments
	port=0
	while IFS=':' read A B;do
		if [ "$A" = "http" ]
		then
			port=80
		elif [ "$A" = "https" ]
		then
			port=443
		fi
		echo "$A ${B:2} $port" >> $HostList
	done < $Tmp

	#DIRBUSTER

	echo
	echo "+++BURP SPIDER & SCAN+++"
	echo "[*] Launching burp scan against $(wc -l < $HostList) URL(s)..."
	echo "This scan runs in the background and may take awhile. Be patient."
	cat $HostList | xargs -L1 java -jar -Xmx1024m -Djava.awt.headless=true $burpPath
	echo "[*] Burp completed."
	echo
	endtime=$(date +"%s")
	echo "DONE. Reports stored in $ReportPath"
	duration=$((endtime-starttime))
	echo "Duration: $(($duration / 60)) minutes and $(($duration % 60)) seconds"

	#move sitemap to report folder
	mv "/root/Tools/burp/carbonator/BurpState" "$ReportPath/BurpState"
	mv "/root/Tools/burp/carbonator/SiteMap.txt" "$ReportPath/SiteMap.txt"
	mv /root/Tools/burp/carbonator/Burp_Carbonator*.html "$ReportPath/"

	#cleanup
	rm $Tmp
	rm $HostList
	rm $nMapUrls
	rm $EyeWitnessReport

	#open report directory in gui
	xdg-open $ReportPath

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
