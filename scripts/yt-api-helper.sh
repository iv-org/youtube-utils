#!/bin/sh
# shellcheck disable=SC2236,SC2237
#
# ^ Allow the use of `! -z` and `! [ -z]` as those are
# more intuitive than `-n`


print_usage()
{
	(
		echo "Usage: yt-api-helper  -i [-c <client>] [-e <endpoint>]"
		echo "Usage: yt-api-helper  -c <client> -e <endpoint> -d <data>"
	) >&2
}

print_help()
{
	print_usage

	(
		echo ""
		echo "Options:"
		echo "  -c,--client       Client to use. Mandatory in non-interactive mode."
		echo "  -d,--data         Raw data to send to the API"
		echo "  -e,--endpoint     Youtube endpoint to request."
		echo "                      Mandatory in non-interactive mode"
		echo "  -h,--help         Show this help"
		echo "  -i,--interactive  Run in interactive mode"
		echo "  -o,--output       Print output to file instead of stdout"
		echo ""
		echo "     --debug        Show what is sent to the API"
		echo ""
	) >&2

	print_clients
	print_endpoints
}

print_clients()
{
	(
		echo ""
		echo "Available clients:"
		echo " - web"
		echo " - web-embed"
		echo " - web-mobile"
		echo " - android"
		echo " - android-embed"
		echo " - apple-ios"
		echo " - tv-html5"
		echo " - tv-html5-embed"
	) >&2
}

print_endpoints()
{
	(
		echo ""
		echo "Available endpoints:"
		echo " - browse"
		echo " - browse-continuation"
		echo " - next"
		echo " - next-continuation"
		echo " - player"
		echo " - search"
		echo " - resolve"
	) >&2
}


query_with_default()
{
	prompt="$1"
	default="$2"

	printf "%s [%s]: " "$prompt" "$default" >&2
	read -r data

	if [ -z "$data" ]; then
		echo "$default"
	else
		echo "$data"
	fi
}

query_with_error()
{
	prompt="$1"
	error_message="$2"

	printf "%s []: " "$prompt" >&2
	read -r data

	if [ -z "$data" ]; then
		error_msg "$error_message"
		exit 1
	else
		echo "$data"
	fi
}


is_arg()
{
	case $1 in
		-c|--client)      true;;
		-d|--data)        true;;
		-e|--endpoint)    true;;
		-h|--help)        true;;
		-i|--interactive) true;;
		-o|--output)      true;;
		--debug)          true;;
		*)                false;;
	esac
}


error_msg()
{
	printf "Error: %s\n" "$1" >&2
}


#
# Parameters init
#

interactive=false
debug=false

client_option=""
endpoint_option=""

client_extra_device_make=""
client_extra_device_model=""
client_extra_os_name=""
client_extra_os_vers=""
client_extra_platform=""
client_extra_form_factor=""

data=""


#
# Interactive client selection
#

while :; do
	# Exit if no more arguments to parse
	if [ $# -eq 0 ]; then break; fi

	case $1 in
		-c|--client)
			shift

			if [ $# -eq 0 ] || is_arg "$1"; then
				error_msg "missing argument after -c/--client"
				print_usage
				exit 2
			fi

			client_option=$1
		;;

		-d|--data)
			shift

			if [ $# -eq 0 ] || is_arg "$1"; then
				error_msg "missing argument after -d/--data"
				print_usage
				exit 2
			fi

			data=$1
		;;

		-e|--endpoint)
			shift

			if [ $# -eq 0 ] || is_arg "$1"; then
				error_msg "missing argument after -e/--endpoint"
				print_usage
				exit 2
			fi

			endpoint_option=$1
		;;

		-h|--help)
			print_help
			exit 0
		;;

		-i|--interactive)
			interactive=true
		;;

		-o|--output)
			shift

			if [ $# -eq 0 ] || is_arg "$1"; then
				error_msg "missing argument after -o/--output"
				print_usage
				exit 2
			fi

			output="$1"
		;;

		--debug)
			debug=true
		;;

		*)
			error_msg "unknown argument '$1'"
			print_usage
			exit 2
		;;
	esac

	shift
done


#
# Input validation
#

if [ ! -z "$data" ]; then
	# Can't pass data in interactive mode
	if [ $interactive = true ]; then
		error_msg "-d/--data can't be used with -i/--interactive"
		print_usage
		exit 2
	fi

	# In non-interactive mode, we still need to pass a client
	# so the right API key is passed as a URL parameter
	if [ -z "$client_option" ]; then
		error_msg "-c/--client is required to select an API key"
		print_usage
		exit 2
	fi

	# Endpoint must be given if non-interactive mode
	if [ -z "$endpoint_option" ]; then
		error_msg "In non-interactive mode, an endpoint must be passed with -e/--endpoint"
		print_usage
		exit 2
	fi
fi

if [ -z "$data" ] && [ $interactive = false ]; then
	# Data must be given if non-interactive mode
	error_msg "In non-interactive mode, data must be passed with -d/--data"
	print_usage
	exit 2
fi

if [ -z "$output" ] && [ $interactive = true ]; then
	confirm=$(query_with_default "\nIt's recommended to use --output in interactive mode.\nContinue?" "No")

	case $confirm in
		[Yy]|[Yy][Ee][Ss]) ;;
		*) exit 0;;
	esac
fi


#
# Client selection
#

if [ -z "$client_option" ]; then
	if [ $interactive = true ]; then
		print_clients
		client_option=$(query_with_default "\nEnter a client to use" "web")
	else
		exit 2
	fi
fi

case $client_option in
	web)
		apikey="AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8"
		client_name="WEB"
		client_vers="2.20230217.01.00"
	;;

	web-embed)
		apikey="AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8"
		client_name="WEB_EMBEDDED_PLAYER"
		client_vers="1.20230217.01.0"
	;;

	web-mobile)
		apikey="AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8"
		client_name="MWEB"
		client_vers="2.20230216.06.00"
	;;

	android)
		apikey="AIzaSyA8eiZmM1FaDVjRy-df2KTyQ_vz_yYM39w"
		client_name="ANDROID"
		client_vers="17.31.35"
	;;

	android-embed)
		apikey="AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8"
		client_name="ANDROID_EMBEDDED_PLAYER"
		client_vers="17.31.35"
	;;

	apple-ios)
		apikey="AIzaSyB-63vPrdThhKuerbB2N_l7Kwwcxj6yUAc"
		client_name="IOS"
		client_vers="17.31.4"

		client_extra_device_make="Apple"
		client_extra_device_model="iPhone11,8"
		client_extra_os_vers="15.2.0"

		user_agent="com.google.ios.youtube/17.31.4 (iPhone11,8; U; CPU iOS 15_2 like Mac OS X; en_GB)"
	;;

	tv-html5)
		apikey="AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8"
		client_name="TVHTML5"
		client_vers="7.20220325"
	;;

	tv-html5-embed)
		apikey="AIzaSyAO_FJ2SlqU8Q4STEHLGCilw_Y9_11qcW8"
		client_name="TVHTML5_SIMPLY_EMBEDDED_PLAYER"
		client_vers="2.0"
		screen="EMBED"
	;;

	*)
		error_msg "Unknown client '$client_option'"
		print_clients
		exit 1
	;;
esac


#
# Endpoint selection
#

if [ -z "$endpoint_option" ]; then
	if [ $interactive = true ]; then
		print_endpoints
		endpoint_option=$(query_with_default "\nEnter an endpoint to request" "")
	else
		exit 2
	fi
fi

case $endpoint_option in
	browse)
		endpoint="youtubei/v1/browse"

		if [ $interactive = true ]; then
			browse_id=$(query_with_default "Enter browse ID" "UCXuqSBlHAE6Xw-yeJA0Tunw")
			partial_data="\"browseId\":\"${browse_id}\""
		fi
	;;

	browse-cont*|browse-tok*)
		endpoint="youtubei/v1/browse"

		if [ $interactive = true ]; then
			token=$(query_with_error "Enter continuation token" "token required")
			partial_data="\"continuation\":\"${token}\""
		fi
	;;

	player|next)
		endpoint="youtubei/v1/$endpoint_option"

		if [ $interactive = true ]; then
			vid=$(query_with_default "Enter video ID" "dQw4w9WgXcQ")
			partial_data="\"videoId\":\"${vid}\""

		fi
	;;

	next-cont*|next-tok*)
		endpoint="youtubei/v1/next"

		if [ $interactive = true ]; then
			token=$(query_with_error "Enter continuation token" "token required")
			partial_data="\"continuation\":\"${token}\""
		fi
	;;

	search)
		endpoint="youtubei/v1/search"

		if [ $interactive = true ]; then
			# Get search query, and escape backslashes and double quotes
			query=$(
				query_with_error "Enter your search query" "search term required" |
				sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
			)
			partial_data="\"query\":\"${query}\""
		fi
	;;

	resolve)
		endpoint="youtubei/v1/navigation/resolve_url"

		if [ $interactive = true ]; then
			url=$(query_with_error "Enter URL" "URL required")
			partial_data="\"url\":\"${url}\""
		fi
	;;

	*)
		error_msg "Unknown endpoint '$endpoint_option'"
		print_endpoints
		exit 1
	;;
esac


#
# Interactively request additional parameters for the supported endpoints
#

if [ $interactive = true ]
then
	case $endpoint_option in

	browse|player|search)
		params=$(query_with_default "Enter optional parameters (base64-encoded protobuf)" "")

		if [ ! -z "$params" ]; then
			partial_data="${partial_data},\"params\":\"${params}\""
		fi
	;;
	esac
fi

# new line
echo


#
# Interactive language/region selection
#

if [ $interactive = true ]; then
	hl=$(query_with_default "Enter content language (hl)" "en")
	gl=$(query_with_default "Enter content region (gl)"   "US")

	client="\"hl\":\"${hl}\",\"gl\":\"${gl}\""

	client="${client},\"deviceMake\":\"${client_extra_device_make}\""
	client="${client},\"deviceModel\":\"${client_extra_device_model}\""

	if ! [ -z "$screen" ]; then
		client="${client},\"clientScreen\":\"${screen}\""
	fi

	client="${client},\"clientName\":\"${client_name}\""
	client="${client},\"clientVersion\":\"${client_vers}\""

	if ! [ -z "$client_extra_os_name" ]; then
		client="${client},\"osName\":\"${client_extra_os_name}\""
	fi

	if ! [ -z "$client_extra_os_vers" ]; then
		client="${client},\"osVersion\":\"${client_extra_os_vers}\""
	fi

	if ! [ -z "$client_extra_platform" ]; then
		client="${client},\"platform\":\"${client_extra_platform}\""
	fi

	if ! [ -z "$client_extra_form_factor" ]; then
		client="${client},\"clientFormFactor\":\"${client_extra_form_factor}\""
	fi


	data="{\"context\":{\"client\":{$client}},$partial_data}"

	# Basic debug
	if [ $debug = true ]; then
		if command -v jq >&2 >/dev/null; then
			printf "\nSending: %s\n\n" "$data" | jq . >&2
		else
			printf "\nSending: %s\n\n" "$data" | sed 's/{/{\n/g; s/}/\n}/g; s/,/,\n/g' >&2
		fi
	fi
fi


#
# Final command
#

url="https://www.youtube.com/${endpoint}?key=${apikey}"

# Headers
hdr_ct='Content-Type: application/json; charset=utf-8'

if [ -z "$user_agent" ]; then
	user_agent="Mozilla/5.0 (Windows NT 10.0; rv:78.0) Gecko/20100101 Firefox/78.0"
fi

hdr_ua="User-Agent: ${user_agent}"


# Run!
temp_dl=_curl_$(date '+%s')

curl --compressed -H "$hdr_ct" -H "$hdr_ua" --data "$data" "$url" | \
sed -E '
	/^\s+"(clickT|t)rackingParams.+,$/d
	s/,?\n\s+"(clickT|t)rackingParams.+$//
' > "$temp_dl"

# Print to STDOUT if no output file was given
if [ -z "$output" ]; then
	cat "$temp_dl"
	rm "$temp_dl"
else
	mv -- "$temp_dl" "$output"
fi
