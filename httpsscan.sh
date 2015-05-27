#!/usr/bin/env bash

# Script to test the most security flaws on a target SSL/TLS.
# Author:  Alexos (alexos at alexos dot org)
# Date:    03-05-2015
# Version: 1.0
#
# References:
# OWASP Testing for Weak SSL/TLS Ciphers, Insufficient Transport Layer Protection 
# https://www.owasp.org/index.php/Testing_for_Weak_SSL/TLS_Ciphers,_Insufficient_Transport_Layer_Protection_%28OTG-CRYPST-001%29
# CVE-2011-1473
# https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2011-1473
# CVE-2012-4929
# https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2012-4929
# CVE-2013-2566
# https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2013-2566
# CVE-2014-0160
# https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2014-0160
# CVE-2014-3566
# https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2014-3566
# CVE-2015-0204
# https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2015-0204
# CVE-2015-4000
# https://web.nvd.nist.gov/view/vuln/detail?vulnId=CVE-2015-4000
# Forward Secrecy
# http://blog.ivanristic.com/2013/06/ssl-labs-deploying-forward-secrecy.html
# Patching the SSL/TLS on Nginx and Apache Webservers
# http://alexos.org/2014/01/configurando-a-seguranca-do-ssl-no-apache-ou-nginx/

VERSION=1.6
clear

echo ":::    ::::::::::::::::::::::::::::::::::  ::::::::  ::::::::  ::::::::     :::    ::::    ::: "
echo ":+:    :+:    :+:        :+:    :+:    :+::+:    :+::+:    :+::+:    :+:  :+: :+:  :+:+:   :+: "
echo "+:+    +:+    +:+        +:+    +:+    +:++:+       +:+       +:+        +:+   +:+ :+:+:+  +:+ "
echo "+#++:++#++    +#+        +#+    +#++:++#+ +#++:++#+++#++:++#+++#+       +#++:++#++:+#+ +:+ +#+ "
echo "+#+    +#+    +#+        +#+    +#+              +#+       +#++#+       +#+     +#++#+  +#+#+# "
echo "#+#    #+#    #+#        #+#    #+#        #+#    #+##+#    #+##+#    #+##+#     #+##+#   #+#+ "
echo "###    ###    ###        ###    ###        ########  ########  ######## ###     ######    #### "
echo "V. $VERSION by Alexos Core Labs                                                        "

if [ $# -ne 2 ]; then
   echo Usage: $0 IP PORT
   exit
fi

HOST=$1
PORT=$2
TARGET=$HOST:$PORT
red=`tput setaf 1`
reset=`tput sgr0`

function ssl2 {
ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -ssl2 -connect "$TARGET" 2>/dev/null`"

proto=`echo "$ssl" | grep '^ *Protocol *:' | awk '{ print $3 }'`
cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`

if [ "$cipher" = '' ]; then
        echo 'Not vulnerable.  Failed to establish SSLv2 connection.'
else
        echo "Vulnerable!  SSLv2 connection established using $proto/$cipher"
fi
}

function crime {
ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -connect "$TARGET" 2>/dev/null`"
compr=`echo "$ssl" |grep 'Compression: ' | awk '{ print $2 } '`

if [ "$compr" = 'NONE' ]; then
        echo 'Not vulnerable. TLS Compression is not enabled.'
else
        echo "Vulnerable! Connection established using $compr compression."
fi
}

function rc4 {
ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -cipher RC4 -connect "$TARGET" 2>/dev/null`"
proto=`echo "$ssl" | grep '^ *Protocol *:' | awk '{ print $3 }'`
cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`
if [ "$cipher" = '' ]; then
echo 'Not vulnerable. Failed to establish RC4 connection.'
else
echo "Vulnerable! Connection established using $proto/$cipher"
fi
}

function heartbleed {
ssl="`echo "QUIT"|openssl s_client -connect "$TARGET" -tlsextdebug 2>&1|grep 'server extension "heartbeat" (id=15)' || echo safe 2>/dev/null`"

if [ "$ssl" = 'safe' ]; then
        echo 'The host is not vulnerable to Heartbleed attack.'
else
        echo "The host is vulnerable to Heartbleed attack."
fi
}

function poodle {
ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -ssl3 -connect "$TARGET" 2>/dev/null`"

proto=`echo "$ssl" | grep '^ *Protocol *:' | awk '{ print $3 }'`
cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`

if [ "$cipher" = '0000'  -o  "$cipher" = '(NONE)' ]; then
        echo 'Not vulnerable.  Failed to establish SSLv3 connection.'
else
        echo "Vulnerable!  SSLv3 connection established using $proto/$cipher"
fi
}

function freak {
ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -cipher EXPORT -connect "$TARGET" 2>/dev/null`"
cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`
if [ "$cipher" = '' ]; then
         echo 'Not vulnerable.  Failed to establish connection with an EXPORT cipher.'
else
         echo "Vulnerable! Connection established using $cipher"
fi
}

function null {
ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -cipher NULL -connect "$TARGET" 2>/dev/null`"
cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`
if [ "$cipher" = '' ]; then
         echo 'Not vulnerable.  Failed to establish connection with a NULL cipher.'
else
         echo "Vulnerable! Connection established using $cipher"
fi
}


function weak40 {
ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -cipher EXPORT40 -connect "$TARGET" 2>/dev/null`"

cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`

if [  "$cipher" = '' ]; then
        echo 'Not vulnerable. Failed to establish connection with 40 bit cipher.'
else
        echo "Vulnerable! Connection established using 40 bit cipher"
fi
}


function weak56 {
ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -cipher EXPORT56 -connect "$TARGET" 2>/dev/null`"

cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`

if [  "$cipher" = '' ]; then
        echo 'Not vulnerable. Failed to establish connection with 56 bit cipher.'
else
        echo "Vulnerable! Connection established using 56 bit cipher"
fi
}

function forward {
ssl="`echo 'Q' | ${timeout_bin:+$timeout_bin 5} openssl s_client -cipher 'ECDH:DH' -connect "$TARGET" 2>/dev/null`"

proto=`echo "$ssl" | grep '^ *Protocol *:' | awk '{ print $3 }'`
cipher=`echo "$ssl" | grep '^ *Cipher *:' | awk '{ print $3 }'`

if [ "$cipher" = ''  -o  "$cipher" = '(NONE)' ]; then
        echo 'Forward Secrecy is not enabled.'
else
        echo "Enabled! Established using $proto/$cipher"
fi
}
echo
echo [*] Analyzing SSL/TLS Vulnerabilities on $HOST:$PORT ...
echo
echo Generating Report...Please wait
echo
echo "${red}==> ${reset} Checking SSLv2 (CVE-2011-1473)"
echo
ssl2
echo
echo "${red}==> ${reset} Checking CRIME (CVE-2012-4929)"
echo
crime
echo
echo "${red}==> ${reset} Checking RC4 (CVE-2013-2566)"
echo
rc4
echo
echo "${red}==> ${reset} Checking Heartbleed (CVE-2014-0160)"
echo
heartbleed
echo
echo "${red}==> ${reset} Checking Poodle (CVE-2014-3566)"
echo
poodle
echo
echo "${red}==> ${reset} Checking FREAK (CVE-2015-0204)/Logjam (CVE-2015-4000)"
echo
freak
echo
echo "${red}==> ${reset}Checking NULL Cipher"
echo
null
echo
echo "${red}==> ${reset} Checking Weak Ciphers"
echo
weak40
echo
weak56
echo
echo "${red}==> ${reset}Checking Forward Secrecy"
echo
forward
echo
#echo
#echo [*] Checking Preferred Server Ciphers
#sslscan $HOST:$PORT > $LOGFILE
#cat $LOGFILE| sed '/Prefered Server Cipher(s):/,/^$/!d' | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[m|K]//g"
#rm $LOGFILE
echo [*] done
