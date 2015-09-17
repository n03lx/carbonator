# carbonator
Integris Security Carbonator - The Burp Suite Pro extension that automates scope, spider &amp; scan from the command line. Carbonator helps automate the vulnerability scanning of web applications. Either 1 or 100 web applications can be scanned by issuing a single command.  Carbonator is now available from within Burp Suite Pro through the BApp Store.

Usage: ./launchburp.sh [required: target domain or IP] [optional: phone number]

Modified features:
* nMap scan against post 80 and 443 to determine protocol
* EyeWitness screen capture
* Automatically builds URL file to feed into existing carbonator extender
* Burp spider and active scan, generates html report, sitemap, and state file
