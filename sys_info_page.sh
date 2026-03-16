#!/bin/bash

# Program to output a system information page

title="System Information Report For : $HOSTNAME"
CURRENT_TIME=$(date +"%x %r %Z")
TIMESTAMP="Generated $CURRENT_TIME, by $USER"

report_uptime() {
	cat <<- _EOF_
		<H2>System Uptime</H2>
		<PRE>$(uptime)</PRE>
		_EOF_
	return
}

report_disk_space() {
	cat <<- _EOF_
		<H2>Disk Space Utilization</H2>
		<PRE>$(df -h)</PRE>
		_EOF_
	return 
}

report_home_space() {
	cat <<- _EOF_
		<H2>Home Space Utilization</H2>
		<PRE>$(du -sh /home/*)</PRE>
		_EOF_
	return
}

echo "<HTML>
        <HEAD>
                <TITLE>$title</TITLE>
        </HEAD>
        <BODY>
                <H1>$title</H1>
		<P>$TIMESTAMP</P>
		$(report_uptime)
		$(report_disk_space)
		$(report_home_space)
        </BODY>
</HTML>"
