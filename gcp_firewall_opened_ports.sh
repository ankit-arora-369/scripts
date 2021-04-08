#!/bin/bash

# Define project name
project_name="<enter gcp project here>"

# Enter VPC name
vpc_name="<enter VPC name>"

# Network series which we have to monitor.
series="0.0.0.0/0"

# Ports to exclude
port1="tcp:80"
port2="tcp:443"

function public_ports {

	# Filtering and writing the resource description to a file.
	gcloud compute firewall-rules list --project "$project_name" --format="table(
	          name,
	          network,
	          direction,
	          priority,
	          sourceRanges.list():label=SRC_RANGES,
	          destinationRanges.list():label=DEST_RANGES,
	          allowed[].map().firewall_rule().list():label=ALLOW,
	          denied[].map().firewall_rule().list():label=DENY,
	          sourceTags.list():label=SRC_TAGS,
	          sourceServiceAccounts.list():label=SRC_SVC_ACCT,
	          targetTags.list():label=TARGET_TAGS,
	          targetServiceAccounts.list():label=TARGET_SVC_ACCT,
	          disabled
		  )" | grep "$vpc_name" | grep "$series" | awk '{print $1, "     "$3, "     ", $5, "     ", $6, "     ", $7}' > firewall_rules.txt

	touch ports_found.txt

	for i in `cat firewall_rules.txt | awk '{print $4}'`
	do
		if [[ $i == *['!'@#\$%^\&*()_,+]* ]]
		then
			for j in `echo "$i" | sed 's/,/ /g'`
			do
				if ! [[ "$j" = "$port1" || "$j" = "$port2" ]]
				then
					echo "Port $j opened in firewall `cat firewall_rules.txt | grep "$j" | awk '{print $1}'`" >> ports_found.txt
				fi
			done
		else
			for k in `echo "$i" | grep -v ","`
	                do
	                        if ! [[ "$k" = "$port1" || "$k" = "$port2" ]]
	                        then
					echo "Port $k opened in firewall `cat firewall_rules.txt | grep "$k" | awk '{print $1}'`" >> ports_found.txt
	                        fi
			done
		fi
	done

	output=`cat ports_found.txt`
	if [[ $output != "" ]]
	then
		## Enter your notification curl below...
		curl -X POST -H 'Content-type: application/json' --data '{"text":"*Firewall Ports opened to World are :* \n'"$output"'"}' https://hooks.slack.com/services/xxxxxxxx/xxxxxxxxxxxxxxxxxxxxx
		sleep 3
		rm -rf ports_found.txt
	else
		curl -X POST -H 'Content-type: application/json' --data '{"text":"*No Opened Public Ports found in Firewalls*"}' https://hooks.slack.com/services/xxxxxxxxxxxxxxxxx/xxxxxxxxxxxxxxxxxxxxxxxxxxx
	fi
}

## Invoking the function.
public_ports
