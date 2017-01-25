#!/bin/bash

takipi_download_url="https://app.takipi.com/app/download?t=t4c-tgz&r=t4c-tgz-installer"

SCRIPTNAME=takipi-installer

##########################################
# Change Takipi installation folder here #
TAKIPI_BASE=/opt
##########################################

os_name=""
verbose="0"
machine_arch=""
machine_name=""
has_wget="0"
has_curl="0"
lib32_dir=""
lib64_dir=""
takipi_default_file=""
takipi_config_file=""
temp_takipi_tar=""
takipi_https_proxy=""
takipi_secret_key=""
skip_java_version_check="0"
is_from_oneliner="0"
skip_secret_key="0"
skip_extract_tarball="0"
has_connection="1"
java_exe=""
use_default_file="1"
skip_agent_setup_instructions="0"
advanced_init="1"
init_type="sysvinit"
listen_on_port=""
daemon_host=""
daemon_port=""
aos_passphrase=""
tarball_local_path=""
java_heap_size=""

do_fpm_install="0"
do_install="0"
do_uninstall="0"
do_reinstall="0"
do_setup_secret_key="0"
do_setup_machine_name="0"
do_setup_proxy="0"
do_setup_smart_attach="0"
do_setup_auto_attach="0"
do_setup_ide_attach="0"
do_setup_auto_update="0"
do_start_service="0"
do_stop_service="0"
do_install_jdk="0"
do_setup_listen_on_port="0"
do_setup_daemon_host="0"

takipi_home=$TAKIPI_BASE/takipi
takipi_jdk_home=$TAKIPI_BASE/takipi-jdk
takipi_base_url=https://backend.takipi.com/
takipi_native_libraries=$takipi_home/lib
takipi_bootstrap_jar=$takipi_home/jars/takipi-bootstrap.jar
auto_agent="0"
ide_attach="0"
auto_update="1"
smart_attach="0"
interactive_mode="1"
start_daemon="1"
check_connection="0"
check_connection_max_retries=3
no_check_certificate="0"
force_kill_daemon="0"
is_aos_mode="0"
service_id=""
check_verbs_count="1"

function log()
{
	message=$1

	[ "$verbose" = "1" ] && echo $message
}

function command_exists()
{
	program=$1

	which which >/dev/null 2>&1

	if [ $? -eq "0" ]; then
		which $program
	else
		for cur_path in ${PATH//:/ }; do
		    if [ -x "$cur_path/$program" ]; then
		    	return 0
		    fi
		done

		return 1
	fi
}

function run()
{
	cmd=$1
	force_log=$2

	if [ "$verbose" = "1" -o "$force_log" = "1" ]; then
		$cmd
	else
		$cmd >/dev/null 2>&1
	fi

	return $?
}

function parse_command_line()
{
	optspec=":hviud-:"

	while getopts "$optspec" optchar; do
	case "${optchar}" in
			-)
			case "${OPTARG}" in
				https_proxy)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					takipi_https_proxy=$val
					;;
				https_proxy=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					takipi_https_proxy=$val
					;;
				install)
					do_install="1"
					;;
				install=*)
					do_install="1"
					;;
				uninstall)
					do_uninstall="1"
					;;
				uninstall=*)
					do_uninstall="1"
					;;
				verbose)
					verbose="1"
					;;
				verbose=*)
					verbose="1"
					;;
				skipjversion)
					skip_java_version_check="1"
					;;
				skipjversion=*)
					skip_java_version_check="1"
					;;
				secret_key)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					takipi_secret_key=$val
					service_id=(${takipi_secret_key//#/ })
					;;
				secret_key=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					takipi_secret_key=$val
					service_id=(${takipi_secret_key//#/ })
					;;
				sk)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					takipi_secret_key=$val
					service_id=(${takipi_secret_key//#/ })
					;;
				sk=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					takipi_secret_key=$val
					service_id=(${takipi_secret_key//#/ })
					;;
				machine_name)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					machine_name=$val
					;;
				machine_name=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					machine_name=$val
					;;
				listen_on_port)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					listen_on_port=$val
					;;
				listen_on_port=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					listen_on_port=$val
					;;
				daemon_host)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					daemon_host=$val
					;;
				daemon_host=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					daemon_host=$val
					;;
				daemon_port)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					daemon_port=$val
					;;
				daemon_port=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					daemon_port=$val
					;;
				passphrase)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					aos_passphrase=$val
					;;
				passphrase=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					aos_passphrase=$val
					;;
				tarball_local_path)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					tarball_local_path=$val
					;;
				tarball_local_path=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					tarball_local_path=$val
					;;
				default_location)
					is_from_oneliner="1"
					;;
				default_location=*)
					is_from_oneliner="1"
					;;
				setup_secret_key)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					takipi_secret_key=$val
					service_id=(${takipi_secret_key//#/ })
					do_setup_secret_key="1"
					;;
				setup_secret_key=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					takipi_secret_key=$val
					service_id=(${takipi_secret_key//#/ })
					do_setup_secret_key="1"
					;;
				setup_machine_name)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					machine_name=$val
					do_setup_machine_name="1"
					;;
				setup_machine_name=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					machine_name=$val
					do_setup_machine_name="1"
					;;
				setup_proxy)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					takipi_https_proxy=$val
					do_setup_proxy="1"
					;;
				setup_proxy=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					takipi_https_proxy=$val
					do_setup_proxy="1"
					;;
				setup_listen_on_port)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					listen_on_port=$val
					do_setup_listen_on_port="1"
					;;
				setup_listen_on_port=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					listen_on_port=$val
					do_setup_listen_on_port="1"
					;;
				setup_daemon_host)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					daemon_host=$val
					do_setup_daemon_host="1"
					;;
				setup_daemon_host=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					daemon_host=$val
					do_setup_daemon_host="1"
					;;
				start_service)
					do_start_service="1"
					;;
				start_service=*)
					do_start_service="1"
					;;
				stop_service)
					do_stop_service="1"
					;;
				stop_service=*)
					do_stop_service="1"
					;;
				config_attach)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					smart_attach=$val
					do_setup_smart_attach="1"
					;;
				config_attach=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					smart_attach=$val
					do_setup_smart_attach="1"
					;;
				auto_agent)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					auto_agent=$val
					;;
				auto_agent=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					auto_agent=$val
					;;
				auto_attach)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					auto_agent=$val
					do_setup_auto_attach="1"
					;;
				auto_attach=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					auto_agent=$val
					do_setup_auto_attach="1"
					;;
				ide_attach)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					ide_attach=$val
					do_setup_ide_attach="1"
					;;
				ide_attach=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					ide_attach=$val
					do_setup_ide_attach="1"
					;;
				no_check_certificate)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					no_check_certificate="1"
					;;
				no_check_certificate=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					no_check_certificate="1"
					;;
				auto_update)
					val="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
					auto_update=$val
					do_setup_auto_update="1"
					;;
				auto_update=*)
					val=${OPTARG#*=}
					opt=${OPTARG%=$val}
					auto_update=$val
					do_setup_auto_update="1"
					;;
				advanced_init)
					advanced_init="1"
					;;
				legacy_init)
					advanced_init="0"
					;;
				install_jdk)
					do_install_jdk="1"
					;;
				*)
					;;
			esac;;
		v)
			verbose="1"
			;;
		h)
			usage
			;;
		i)
			do_install="1"
			;;
		u)
			do_uninstall="1"
			;;
		d)
			is_from_oneliner="1"
			;;
		*)
			;;
		esac
	done
}

function init_os()
{
	log "Detecting distro..."

	if [ ! "$os_name" ]; then
		if [ -f /etc/lsb-release ]; then
			distrib_line=$(cat /etc/lsb-release | grep '^DISTRIB_ID=')
			if [ ! -z "$distrib_line" ]; then
				os_name=${distrib_line:11}
			fi
		fi
	fi

	if [ ! "$os_name" ]; then
		if [ -f /etc/os-release ]; then
			id_like_line=$(cat /etc/os-release | grep '^ID_LIKE=')
			if [ ! -z "$id_like_line" ]; then
				id_like=${id_like_line:8}
				if [ "$id_like" = "suse" -o "$id_like" = "\"suse\"" ]; then
					os_name="SuSE"
				fi
			fi
		fi
	fi

	if [ "$os_name" ]; then
		log "$os_name detected."
	elif [ -f /etc/debian_version ]; then
		os_name="Ubuntu"
		log "Ubuntu/Debian detected."
	elif [ -f /etc/redhat-release ]; then
		os_name="Redhat"
		log "RedHat/Fedora detected."
	elif [ -f /etc/centos-release ]; then
		os_name="Redhat"
		log "CentOS detected."
	elif [ -f /etc/gentoo-release ]; then
		os_name="Gentoo"
		log "Gentoo detected."
	elif [ -f /etc/alpine-release ]; then
		os_name="Alpine"
		log "Alpine detected."
	elif [ -f /etc/SuSE-release ]; then
		os_name="SuSE"
		log "SuSE detected."
	elif [ -f /etc/arch-release ]; then
		os_name="Arch"
		log "Arch Linux detected."
	elif [ -f /etc/system-release ]; then
		os_name="Redhat"
		log "Amazon Linux assumed."
	elif [ -d /etc/sysconfig ]; then
		if [ -f /etc/init.d/functions ]; then
			os_name="Redhat"
			log "RedHat/Fedora assumed."
		elif [ -f /etc/rc.status ]; then
			os_name="SuSE"
			log "SuSE assumed."
		fi
	elif [ -d /etc/conf.d ]; then
		os_name="Gentoo"
		log "Gentoo assumed."
	elif [ -d /Users ] && [ -d /Applications ]; then
		os_name="OSX"
		log "OSX detected"
	else
		os_name="Ubuntu"
		log "Ubuntu/Debian assumed."
	fi

	if [ "$os_name" = "Ubuntu" -o "$os_name" = "Debian" -o "$os_name" = "Mint" -o "$os_name" = "LinuxMint" -o "$os_name" = "MintLinux" ]; then
		os_name="Ubuntu"
	fi

	if [ "$os_name" = "OSX" ]; then
		run_osx_pkg
		exit 0
	fi

	if [ "$os_name" = "Arch" ]; then
		use_default_file="0"
	fi
}

function init_lib_dirs()
{
	if [ -d "/usr/lib" -a -d "/usr/lib64" ]; then
		lib32_dir="/usr/lib"
		lib64_dir="/usr/lib64"
	elif [ -d "/usr/lib" ]; then
		lib32_dir="/usr/lib32"
		lib64_dir="/usr/lib"
	elif [ -d "/lib" -a -d "/lib64" ]; then
		lib32_dir="/lib"
		lib64_dir="/lib64"
	elif [ -d "/lib" ]; then
		lib32_dir="/lib32"
		lib64_dir="/lib"
	else
		log "Unable to find appropriate lib directory."
		return 1
	fi
}

function general_init()
{
	machine_arch=`uname -m`

	if [ -z "$machine_name" ]; then
		machine_name=`hostname`
	fi

	command_exists wget >/dev/null 2>&1
	
	if [ $? -eq "0" ]; then
		has_wget="1"
	fi

	command_exists curl >/dev/null 2>&1

	if [ $? -eq "0" ]; then
		has_curl="1"
	fi

	if [ -z "$skip_usage" ]; then
		skip_usage="0"
	fi

	if [ "$os_name" = "Ubuntu" ]; then
		takipi_default_file=/etc/default/takipi
	elif [ "$os_name" = "Gentoo" -o "$os_name" = "Alpine" ]; then
		takipi_default_file=/etc/conf.d/takipi
	else # "Redhat" / "SuSE"
		takipi_default_file=/etc/sysconfig/takipi
	fi

	takipi_config_file="$takipi_home/takipi.properties"

	if [ -r "$takipi_default_file" ]; then
		load_takipi_default_file "0"
		is_reinstall="1"
	fi

	if [ -s "$takipi_config_file" ]; then
		load_takipi_config_file "0"
		is_reinstall="1"
	fi

	if [ -z "$takipi_secret_key" -a -r "$takipi_home/work/secret.key" ]; then
		takipi_secret_key=`cat $takipi_home/work/secret.key` >/dev/null 2>&1
		service_id=(${takipi_secret_key//#/ })
	fi

	if [ "$do_install" == "1" ]; then
		unique_temp_file=$(mktemp takipi-latest-XXXXXX)
		temp_takipi_tar="${unique_temp_file}.tar.gz"
		rm -f $unique_temp_file >/dev/null 2>&1

		log "Takipi temp file is: $temp_takipi_tar"
	fi
	
	if [ -n "$daemon_host" -a -n "$daemon_port" -a -z "$listen_on_port" ]; then
		log "AOS mode $daemon_host:$daemon_port"
		is_aos_mode="1"
	fi
	
	if [ -n "$listen_on_port" ]; then
		java_heap_size="1G"
	fi

	daemon=$takipi_home/bin/takipi-service
}

function init()
{
	parse_command_line "$@"
	init_os
	init_lib_dirs
	general_init
}

function validate()
{
	if [ `id -u` -ne 0 ]; then
		echo "You need root privileges to run this script."

		report_install_status 4
		return 1
	fi

	if [ "$machine_arch" != 'x86_64' ]; then
		echo "Takipi is only supported on 64-bit platforms."
		echo "Canceling installation."

		report_install_status 5 "$machine_arch"
		return 1
	fi

	if [ "$has_wget" != "1" -a "$has_curl" != "1" ]; then
		echo "Cannot find wget or curl."
		echo "Please install either wget or curl, and restart the installation."

		report_install_status 70
		return 1
	fi

	if [ "$do_install" == "1" -a "$skip_extract_tarball" != "1" ]; then
		if [ -z "$takipi_download_url" ]; then
			echo "Error: Takipi download URL is empty."
			echo "Aborting installation."

			return 1
		fi

		if [ -n "$service_id" ]; then
			if [[ $takipi_download_url == *"?"* ]]; then
				takipi_download_url="${takipi_download_url}&"
			else
				takipi_download_url="${takipi_download_url}?"
			fi

			takipi_download_url="${takipi_download_url}s=${service_id}"
		fi
	fi

	if [ "$check_verbs_count" == "1" ]; then
		verbsCount=0
		[ "$do_install" == "1" ] && verbsCount=$[$verbsCount +1]
		[ "$do_uninstall" == "1" ] && verbsCount=$[$verbsCount +1]
		[ "$do_reinstall" == "1" ] && verbsCount=$[$verbsCount +1]
		[ "$do_setup_secret_key" == "1" ] && verbsCount=$[$verbsCount +1]
		[ "$do_setup_proxy" == "1" ] && verbsCount=$[$verbsCount +1]
		[ "$do_setup_machine_name" == "1" ] && verbsCount=$[$verbsCount +1]
		[ "$do_setup_smart_attach" == "1" ] && verbsCount=$[$verbsCount +1]
		[ "$do_setup_auto_attach" == "1" ] && verbsCount=$[$verbsCount +1]
		[ "$do_setup_ide_attach" == "1" ] && verbsCount=$[$verbsCount +1]
		[ "$do_setup_auto_update" == "1" ] && verbsCount=$[$verbsCount +1]
		[ "$do_start_service" == "1" ] && verbsCount=$[$verbsCount +1]
		[ "$do_stop_service" == "1" ] && verbsCount=$[$verbsCount +1]
		[ "$do_setup_listen_on_port" == "1" ] && verbsCount=$[$verbsCount +1]
		[ "$do_setup_daemon_host" == "1" ] && verbsCount=$[$verbsCount +1]
		
		if [ "$verbsCount" != "1" ]; then
			usage

			report_install_status 13
			return 1
		fi
	fi

	if [ "$skip_secret_key" == "0" -a "$is_aos_mode" == "0" ]; then

		if [ "$do_install" == "1" -o "$do_setup_secret_key" == "1" ]; then

			if [ -z "$takipi_secret_key" ]; then
				echo "Please provide a secret key."
				echo ""
				usage

				report_install_status 10
				return 1
			fi

			echo "$takipi_secret_key" | grep "^S[1-9][0-9]*#[^#][^#]*#[^#][^#]*#[0-9A-Fa-f]\{4\}$" > /dev/null 2>&1

			if [ $? -ne 0 ]; then
				echo "The secret key is invalid. Please provide a valid secret key."
				echo ""
				usage

				report_install_status 8
				return 1
			fi
		fi
	fi

	if [ ! -d "$lib32_dir" ]; then
		mkdir "$lib32_dir"
	fi

	return 0
}

function download()
{
	from_url=$1
	to_file=$2
	log_level=$3
	timeout=$4
	
	params=""
	download_command=""

	if [ "$has_wget" == "1" ]; then
		if [ "$takipi_https_proxy" != "" ]; then
			params="-e https_proxy=$takipi_https_proxy"
		fi

		if [ "$no_check_certificate" == "1" ]; then
			params="$params --no-check-certificate"
		fi
		
		if [ "$os_name" == "Alpine" ]; then
			download_command="wget -t 5 -O $to_file $from_url" 
		else
			download_command="wget $params -t 5 --connect-timeout=2 -O $to_file $from_url"
		fi
	else
		if [ "$takipi_https_proxy" != "" ]; then
			params="-x $takipi_https_proxy"
		fi

		if [ -n "$timeout" ]; then
			params="-m $timeout $params"
		fi

		if [ "$os_name" == "Alpine" ]; then
			download_command="curl -o $to_file -L $from_url"
		else
			download_command="curl $params -o $to_file -L $from_url"
		fi
	fi
		
	# log_level = 0: Use $verbose
	# log_level = 1: Force log (ignore $verbose)
	# log_level = 2: Silent mode (ignore $verbose)
	#
	if [ "$log_level" == "1" ]; then
		force_log="1"
		silent="0"
	elif [ "$log_level" == "2" ]; then
		force_log="0"
		silent="1"
	else
		force_log="0"
		silent="0"
	fi

	if [ "$silent" == "1" ]; then
		run "$download_command" $force_log >/dev/null 2>&1
	else
		run "$download_command" $force_log
	fi
}

function processPid()
{
	process=$1

	if [ "$os_name" == "Alpine" ]; then
		ps -o pid,comm | grep $process | grep -v grep | awk '{ print $1 }'
	else
		ps -C $process -o pid | tail -n +2 | tr -d ' '
	fi
}

function install_jdk()
{
	temp_takipi_jdk=`mktemp /tmp/takipi-jdk-XXXXXX`
	temp_takipi_jdk="${temp_takipi_pkg}.tar.gz"

	takipi_jdk_download_url="https://s3.amazonaws.com/app-takipi-com/deploy/jdk/takipi-jdk.tar.gz"

	if ! download "$takipi_jdk_download_url" "$temp_takipi_jdk" "1"; then
		return 1
	fi

	tar -C $TAKIPI_BASE -zxf $temp_takipi_jdk >/dev/null 2>&1
	rm -f $temp_takipi_jdk >/dev/null 2>&1
}

function run_osx_pkg()
{
	echo "Downloading Takipi..."

	temp_takipi_pkg=`mktemp /tmp/takipi-XXXXXX`
	temp_takipi_pkg="${temp_takipi_pkg}.pkg"

	takipi_download_url="https://app.takipi.com/app/download?t=pkg&r=nix-installer"

	if ! download "$takipi_download_url" "$temp_takipi_pkg" "1"; then
		return 1
	fi

	echo $takipi_secret_key > /tmp/takipi-skf
	echo $temp_takipi_pkg > /tmp/takipi-dtp

	report_install_status 61

	open "$temp_takipi_pkg"
}

function check_java_version()
{
	java_bin_dir=$1
	jvm_lib_file=""
	java_exe=""

	if [ -z "$java_bin_dir" ]; then
		return 1
	fi

	search_opts="$java_bin_dir $java_bin_dir/bin/java $java_bin_dir/jre/bin/java $java_bin_dir/java"

	parent1=$(dirname $java_bin_dir)
	parent2=$(dirname $parent1)
	parent3=$(dirname $parent2)
	search_opts="$search_opts $parent1/jre/bin/java $parent2/jre/bin/java $parent3/jre/bin/java"

	for java_exe in $search_opts; do

		if [ ! -x $java_exe -o -d $java_exe ]; then
			continue
		fi

		if [ "$skip_java_version_check" == "0" ]; then
			java_version=$("$java_exe" -version 2>&1 | awk -F '"' '/version/ {print $2}')
			bit_version_1=$("$java_exe" -version 2>&1 | awk 'END{print $2}')
			bit_version_2=$("$java_exe" -version 2>&1 | awk 'END{print $3}')

			if [[ "$java_version" < "1.6" ]]; then
				continue
			fi

			if [ "$bit_version_1" != "64-Bit" -a "$bit_version_2" != "64-Bit" ]; then
				continue
			fi
		fi

		java_exe_length=${#java_exe}-9
		lib_file="${java_exe:0:$java_exe_length}/lib/amd64/server/libjvm.so" 2>&1

		if [ ! -r $lib_file ]; then
			continue
		fi

		if [ "$force_jdk" = true ]; then
			if ! does_jvm_belong_to_jdk $java_exe; then
				log "Searching for a JDK - $java_exe is not in a JDK folder"
				continue
			fi
		fi

		log "Java found at $java_exe"
		[ "$skip_java_version_check" = "1" ] && log "Skipped Java version check."

		jvm_lib_file=$lib_file
		return 0

	done

	java_exe=""

	return 1
}

function does_jvm_belong_to_jdk()
{
	java_exe_location=$1

	java_folder_length=${#java_exe_location}-12
	java_folder="${java_exe_location:0:$java_folder_length}"

	tools_file="$java_folder/lib/tools.jar" 2>&1

	if [ -e $tools_file ]; then
   		return 0
	fi

	java_folder_length=${#java_exe_location}-9
	java_folder="${java_exe_location:0:$java_folder_length}"

	tools_file="$java_folder/lib/tools.jar" 2>&1

	if [ -e $tools_file ]; then
		return 0
	fi

	return 1
}

function internal_look_for_java()
{
	if [ -n "$jvm_lib_file" ] && [ -n "$java_exe" ] && [ -r $jvm_lib_file ]; then
		return 0
	fi

	log "Search for Java in $takipi_jdk_home"
	
	if check_java_version "$takipi_jdk_home"; then
		return 0
	fi

	log "Search for Java lib according to JAVA_HOME"

	if [ -n "$JAVA_HOME" ]; then
		if check_java_version "$JAVA_HOME"; then
			return 0
		fi
	fi

	log "Search for Java lib according to PATH"

	if type -p java >/dev/null 2>&1; then
		temp_java_bin=$(readlink -f `type -p java`)

		if check_java_version "$temp_java_bin"; then
			return 0
		fi
	fi

	log "Search for Java lib according to pid"

	if search_javalib_according_to_pid; then
		return 0
	fi

	log "Brute force to find java"

	if brute_force_java_searching; then
		return 0
	fi

	return 1
}

function look_for_java()
{
	force_jdk=true

	log "Looking for Java - searching for a JDK"

	if internal_look_for_java; then
		return 0
	fi

	force_jdk=false

	log "Looking for java - searching for a JRE"

	if internal_look_for_java; then
		return 0
	fi

	if [ "$interactive_mode" == "1" ]; then
		log "Manually entering java"

		if manually_entering_java; then
			return 0
		fi
	fi

	echo "Java not valid!"
	echo "Please point the JAVA_HOME environment variable to a valid 64-bit Java installation,"
	echo "e.g. 'export JAVA_HOME=/usr/lib/jvm/java-6-openjdk/jre',"
	echo "or make sure the symbolic link at /usr/bin/java is valid."
	echo " "
	echo "Takipi installation aborted!"

	return 1
}

function search_javalib_according_to_pid()
{
	report_install_status 53

	temp_java_bin=""
	java_pids=`processPid java`

	for pid in $java_pids; do
		temp_java_bin=$(readlink -f "/proc/$pid/exe")

		if check_java_version "$temp_java_bin"; then
			report_install_status 54
			return 0
		fi
	done

	report_install_status 55
	return 1
}

function manually_entering_java()
{
	report_install_status 50

	user_temp_java_bin=""
	echo "Takipi was not able to automatically locate a valid 64-bit Java installation."
	read -e -p "> Please enter a Java executable path (e.g. /usr/bin/java): " user_temp_java_bin < /dev/tty

	temp_java_bin=$(readlink -f "$user_temp_java_bin")

	if check_java_version "$temp_java_bin" ; then
		report_install_status 51
		return 0
	else
		report_install_status 52
		return 1
	fi
}

function brute_force_java_searching()
{
	common_jdks="$takipi_jdk_home /usr/java/default /usr/lib/jvm/java /usr/java/default-java /usr/lib/jvm/java-6-openjdk /usr/lib/jvm/java-6-sun /usr/lib/jvm/java-1.5.0-sun /usr/lib/j2sdk1.5-sun /usr/lib/j2sdk1.5-ibm /usr/lib/jvm/jre /usr/lib/jvm/default-java /usr/java /usr/java/latest /usr/lib/jvm/java-6-openjdk-amd64 /usr/lib/jvm/java-7-openjdk /usr/lib/jvm/java-7-openjdk-amd64 /usr/lib/jvm/java-7-sun /usr/lib/jvm/java-openjdk /usr/lib/jvm/java-7-oracle /usr/lib/jvm/oracle-jre-bin-1.7 /usr/lib/jvm/oracle-jre-bin-1.6"

	for java_home in $common_jdks; do
		temp_java_bin=$(readlink -f "$java_home/bin/java")

		if check_java_version "$temp_java_bin"; then
			return 0
		fi

		temp_java_bin=$(readlink -f "$java_home/jre/bin/java")

		if check_java_version "$temp_java_bin"; then
			return 0
		fi
	done

	return 1
}

function get_proxy_from_user()
{
	if [ "$interactive_mode" == "0" ]; then
		return
	fi

	echo "Could not establish a connection to Takipi's server."
	echo "If you are behind a proxy, please enter its details (e.g. \"http://user:pass@192.168.1.101:8080\")."

	while true; do

		read -e -p "Proxy address (leave empty to skip): " takipi_https_proxy < /dev/tty

		if [ "$takipi_https_proxy" == "" ]; then
			return
		fi

		if do_check_connection; then
			return
		fi

		echo "We still couldn't reach Takipi's servers. Please enter a valid proxy address."

	done
}

function do_smart_attach()
{
	preprocess_smart_attach -a attach $@
}

function do_smart_detach()
{
	preprocess_smart_attach -a detach $@
}

function preprocess_smart_attach()
{
	smart_attach_args="$@"

	takipi_id=""

	if [ -n "$takipi_secret_key" ]; then
		takipi_id=(${takipi_secret_key//#/ })

		smart_attach_args="$smart_attach_args -k $takipi_id"
	fi

	if [ -n "$takipi_base_url" ]; then
		smart_attach_args="$smart_attach_args -b $takipi_base_url"
	fi

	if [ "$verbose" = "1" ]; then
		smart_attach_args="$smart_attach_args -v"
	fi

	run_smart_attach $smart_attach_args
}

function run_smart_attach()
{
	if [ ! -r $takipi_bootstrap_jar ]; then
		return 0
	fi

	look_for_java

	if [ ! -x "$java_exe" ]; then
		return 1
	fi

	$java_exe -cp $takipi_bootstrap_jar m.M smartattach $@

	return 0
}

function parse_proxy()
{
	user=""
	pass=""
	host=""
	port=""
	
	proxySuffix=${takipi_https_proxy##*/}

	IFS='@' read -ra proxy <<< "$proxySuffix"

	if [ ${#proxy[@]} == 2 ]; then

		IFS=':' read -ra userAndPass <<< "${proxy[0]}"

		if [ ${#userAndPass[@]} == 2 ]; then
			user=${userAndPass[0]}
			pass=${userAndPass[1]}
		fi

		IFS=':' read -ra hostAndPort <<< "${proxy[1]}"

		if [ ${#hostAndPort[@]} == 2 ]; then
			host=${hostAndPort[0]}
			port=${hostAndPort[1]}
		fi
	fi

	if [ ${#proxy[@]} == 1 ]; then

		IFS=':' read -ra hostAndPort <<< "${proxy[0]}"

		if [ ${#hostAndPort[@]} == 2 ]; then
			host=${hostAndPort[0]}
			port=${hostAndPort[1]}
		fi

	fi
}

function do_check_connection()
{
	if [ "$check_connection" == "0" ]; then
		return 0
	fi

	parse_proxy
	
	params="-backendUrl $takipi_base_url"
	
	if [ "$verbose" == "1" ]; then
		params="$params -verbose true"
	fi
	
	$java_exe "-Dhttps.proxyHost="$host "-Dhttps.proxyPort="$port "-Dhttps.proxyUser="$user "-Dhttps.proxyPassword="$pass -cp $takipi_bootstrap_jar m.M checkconnection $params

	x=$?

	return $x
}

function prepare_takipi_home()
{
	if [ "$skip_extract_tarball" == "1" ]; then
		return 0
	fi
	
	if [ -z "$tarball_local_path" ]; then
		echo "Getting the latest Takipi version..."

		if ! download $takipi_download_url $temp_takipi_tar "1"; then
			echo ""
			echo "Aborting. Unable to download: $takipi_download_url"
			echo ""
			echo "Takipi's installer was not able to communicate with the server."
			echo ""
			echo "Are you running behind a proxy/firewall? Learn how to set up your proxy:"
			echo "  https://support.takipi.com/hc/en-us/articles/218721168#running-behind-a-proxy"
			echo ""
			
			rm -f $temp_takipi_tar >/dev/null 2>&1

			report_install_status 1
			return 1
		fi
		
		log "File downloaded successfully."

		tar -C $TAKIPI_BASE -zxf $temp_takipi_tar >/dev/null 2>&1
		rm -f $temp_takipi_tar >/dev/null 2>&1
	else
		log "Extracting $tarball_local_path to $TAKIPI_BASE"
		tar -C $TAKIPI_BASE -zxf $tarball_local_path
	fi

	return 0
}

function registering_dynamic_libraries()
{
	log "Registering Takipi with the dynamic linker..."

	if [ -d "/etc/ld.so.conf.d" ]; then
		echo "$takipi_home/lib" > /etc/ld.so.conf.d/takipi.conf
	else # Alpine
		echo "$takipi_home/lib" >> /etc/ld.so.conf
	fi

	ldconfig >/dev/null 2>&1
	/sbin/ldconfig >/dev/null 2>&1
}

function install_takipi()
{
	if ! look_for_java; then
		return 1
	fi

	stop_takipi

	if ! prepare_takipi_home; then
		return 1
	fi

	if ! do_check_connection; then
		has_connection="0"
	fi

	if [ "$has_connection" == "0" ]; then
		get_proxy_from_user
	fi
	
	export TAKIPI_HOME=$takipi_home
	export TAKIPI_BASE_URL=$takipi_base_url
	export TAKIPI_NATIVE_LIBRARIES=$takipi_native_libraries
	export JVM_LIB_FILE=$jvm_lib_file
	export DAEMON=$daemon

	save_takipi_default_file
	save_takipi_config_file

	chmod 777 $takipi_home/log/agents
	chmod 777 $takipi_home/resources

	registering_dynamic_libraries
	
	choose_init_type
	configure_init 0
	
	log "Registering..."

	setup_secret_key

	echo "Takipi installed successfully."
	echo "This machine's name is \"$machine_name\". You can change it by running: /opt/takipi/etc/takipi-setup-machine-name <machine-name>."
}

function install_takipi_aos()
{
	if ! prepare_takipi_home; then
		return 1
	fi
	
	registering_dynamic_libraries
	save_takipi_config_file
	chmod 777 $takipi_home/resources
	
	echo "Takipi installed successfully."
}

function choose_init_type()
{
	has_systemd="false"
	has_upstart="false"

	command_exists systemctl >/dev/null 2>&1

	if [ $? -eq "0" ]; then
		report_install_status 71 "systemd"
		has_systemd="true"

		log "Init daemon available: systemd"
	fi

	command_exists initctl >/dev/null 2>&1

	if [ $? -eq "0" ]; then
		report_install_status 71 "upstart"
		has_upstart="true"

		log "Init daemon available: upstart"
	fi

	if [ "$os_name" == "Alpine" ]; then
		init_type="openrc"
	elif [ "$has_systemd" == "true" ]; then
		init_type="systemd"
	elif [ "$has_upstart" == "true" ]; then
		init_type="upstart"
	else
		init_type="sysvinit"
	fi

	log "Chosen init daemon: $init_type"
}

function configure_init()
{
	# phantom state is when we only change the value of init_type without doing any work, like copying files.
	phantom_state=$1

	if [[ "$advanced_init" == "1" && ("$os_name" = "Ubuntu" || "$os_name" = "Redhat") ]]; then
		if [[ "$os_name" == "Ubuntu" && "$init_type" == "systemd" ]]; then
			init_type="sysvinit" # systemd currently falls back to sysvinit in Ubuntu
		fi

		if [ $phantom_state -ne "1" ]; then
			if [ "$os_name" == "Ubuntu" ]; then
				if [ "$init_type" == "upstart" ]; then
					cp -f $takipi_home/etc/takipi.init-upstart /etc/init/takipi.conf
					chmod 644 /etc/init/takipi.conf 
				else
					cp -f $takipi_home/etc/takipi.init-debian /etc/init.d/takipi
					/usr/sbin/update-rc.d -f takipi remove >/dev/null 2>&1
					/usr/sbin/update-rc.d takipi defaults >/dev/null 2>&1
				fi
			elif [ "$os_name" = "Redhat" ]; then
				if [ "$init_type" == "upstart" ]; then
					cp -f $takipi_home/etc/takipi.init-upstart-rhel /etc/init/takipi.conf
					chmod 644 /etc/init/takipi.conf
				elif [ "$init_type" == "systemd" ]; then
					cp -f $takipi_home/etc/takipi.init-systemd /lib/systemd/system/takipi.service
					systemctl daemon-reload >/dev/null 2>&1
					systemctl enable takipi.service >/dev/null 2>&1
				else # sysvinit
					cp -f $takipi_home/etc/takipi.init-rhel /etc/init.d/takipi
					/sbin/chkconfig takipi on >/dev/null 2>&1
				fi
			fi
		fi
	else
		if [ "$os_name" = "Arch" ]; then
			init_type="systemd"
		else
			init_type="sysvinit"
		fi

		if [ $phantom_state -ne "1" ]; then
			if [ "$os_name" = "Ubuntu" ]; then
				cp -f $takipi_home/etc/takipi.init-debian /etc/init.d/takipi
				/usr/sbin/update-rc.d -f takipi remove >/dev/null 2>&1
				/usr/sbin/update-rc.d takipi defaults >/dev/null 2>&1
			elif [ "$os_name" = "Gentoo" -o "$os_name" = "Alpine" ]; then
				cp -f $takipi_home/etc/takipi.init-gentoo /etc/init.d/takipi
				/sbin/rc-update del takipi default >/dev/null 2>&1
				/sbin/rc-update add takipi default >/dev/null 2>&1
			elif [ "$os_name" = "SuSE" ]; then
				cp -f $takipi_home/etc/takipi.init-suse /etc/init.d/takipi
				/sbin/insserv -r takipi >/dev/null 2>&1
				/sbin/insserv -d takipi >/dev/null 2>&1
			elif [ "$os_name" = "Arch" ]; then
				cp -f $takipi_home/etc/takipi.init-systemd /lib/systemd/system/takipi.service
				systemctl daemon-reload >/dev/null 2>&1
				systemctl enable takipi.service >/dev/null 2>&1
			else # "Redhat"
				cp -f $takipi_home/etc/takipi.init-rhel /etc/init.d/takipi
				/sbin/chkconfig takipi on >/dev/null 2>&1
			fi
		fi
	fi

	if [ $phantom_state -ne "1" ]; then
		if [ -f "/etc/init.d/takipi" ]; then
			chmod +x /etc/init.d/takipi
		fi
	fi

	log "Configured init daemon: $init_type"
}

function install_auto_agent()
{
	ln -sf $takipi_home/lib32/libTakipiAgent.so $lib32_dir/libTakipiAgent.so >/dev/null 2>&1
	ln -sf $takipi_home/lib/libTakipiAgent.so $lib64_dir/libTakipiAgent.so >/dev/null 2>&1

	ldconfig >/dev/null 2>&1
	/sbin/ldconfig >/dev/null 2>&1

	if [ -f $takipi_home/etc/takipi-env-install ]; then
		$takipi_home/etc/takipi-env-install uninstall $takipi_home/lib/libTakipiAgent.so
		$takipi_home/etc/takipi-env-install install $takipi_home/lib/libTakipiAgent.so

		return 0
	else
		log "$takipi_home/etc/takipi-env-install not found."

		return 1
	fi
}

function install_agent_manually()
{
	if [ "$skip_agent_setup_instructions" == "1" ]; then
		return 0;
	fi

	color='\e[1;38;5;208;48;5;232m'
	arg_color='\e[49;96m'
	clear_color='\E[00m'
    
	echo ""
	echo -e "Please restart any Java processes you'd like to monitor with this JVM argument:"
	echo -e "${arg_color}>>>>>>> -agentlib:TakipiAgent <<<<<<<${clear_color}"
	echo -e "${color}Example 1:${clear_color} /usr/bin/java -Xmx128m ${arg_color}-agentlib:TakipiAgent${clear_color} -jar my-app.jar"
	echo -e "Make sure the ${arg_color}'-agentlib'${clear_color} argument is passed before the main class or '-jar' argument."
	echo ""

	TOMCAT_DEFAULT_LOC=""

	if [ "$os_name" = "Ubuntu" ]; then
		TOMCAT_DEFAULT_LOC="/etc/default/tomcat7"
	elif [ "$os_name" = "Gentoo" ]; then
		TOMCAT_DEFAULT_LOC="/etc/conf.d/tomcat7"
	else # "Redhat" / "SuSE"
		TOMCAT_DEFAULT_LOC="/etc/sysconfig/tomcat7"
	fi

	echo -e "${color}Example 2:${clear_color} Running Takipi with Apache Tomcat: Edit $TOMCAT_DEFAULT_LOC and add the argument to the JAVA_OPTS variable."
	echo -e "e.g. JAVA_OPTS=\"${arg_color}-agentlib:TakipiAgent${clear_color} -Xmx128m -XX:+UseConcMarkSweepGC\""
	echo ""
	echo "For more information: www.takipi.com"
}

function install_agent()
{
	if [ "$smart_attach" == "1" ]; then
		do_smart_attach
	fi

	if [ "$auto_agent" == "0" ]; then
		install_agent_manually
	else
		install_auto_agent
	fi
}

function uninstall_auto_agent()
{
	if [ -f $takipi_home/etc/takipi-env-install ]; then
		$takipi_home/etc/takipi-env-install uninstall $takipi_home/lib/libTakipiAgent.so

		return 0
	else
		log "$takipi_home/etc/takipi-env-install not found."

		return 1
	fi
}

function load_takipi_default_file()
{
	if [ "$use_default_file" = "0" ]; then
		return 0
	fi

	override=$1
	. $takipi_default_file

 	[ -z "$takipi_home" -o $override == "1" ] && takipi_home=$TAKIPI_HOME
 	[ -z "$takipi_base_url" -o $override == "1" ] && takipi_base_url=$TAKIPI_BASE_URL
 	[ -z "$takipi_native_libraries" -o $override == "1" ] && takipi_native_libraries=$TAKIPI_NATIVE_LIBRARIES
 	[ -z "$daemon" -o $override == "1" ] && daemon=$DAEMON
 	[ -z "$jvm_lib_file" -o $override == "1" ] && jvm_lib_file=$JVM_LIB_FILE
 	[ -z "$machine_name" -o $override == "1" ] && machine_name=$TAKIPI_MACHINE_NAME
 	[ -z "$takipi_https_proxy" -o $override == "1" ] && takipi_https_proxy=$TAKIPI_HTTPS_PROXY
}

function load_takipi_config_file()
{
	override=$1
	. $takipi_config_file

 	[ -z "$takipi_base_url" -o $override == "1" ] && takipi_base_url=$baseUrl
 	[ -z "$takipi_native_libraries" -o $override == "1" ] && takipi_native_libraries=$libraryPath
 	[ -z "$jvm_lib_file" -o $override == "1" ] && jvm_lib_file=$jvmPath
 	[ -z "$machine_name" -o $override == "1" ] && machine_name=$serverName
 	[ -z "$takipi_https_proxy" -o $override == "1" ] && takipi_https_proxy=$httpsProxy
 	[ -z "$ide_attach" -o $override == "1" ] && ide_attach=$ideAttach
 	[ -z "$auto_update" -o $override == "1" ] && auto_update=$autoUpdate
 	[ -z "$service_id" -o $override == "1" ] && service_id=$serviceId
 	[ -z "$listen_on_port" -o $override == "1" ] && listen_on_port=$listenOnPort
 	[ -z "$daemon_host" -o $override == "1" ] && daemon_host=$masterHost
 	[ -z "$daemon_port" -o $override == "1" ] && daemon_port=$masterPort
 	[ -z "$aos_passphrase" -o $override == "1" ] && aos_passphrase=$passphrase
 	[ -z "$java_heap_size" -o $override == "1" ] && java_heap_size=$javaHeapSize
}

function save_takipi_default_file()
{
	if [ "$use_default_file" = "0" ]; then
		return 0
	fi

	proxy=""

	if [ "$takipi_https_proxy" != "" ]; then
		proxy="TAKIPI_HTTPS_PROXY=$takipi_https_proxy"
	fi

# The echo lines are not indented on purpose 
	echo \
"TAKIPI_HOME=$takipi_home" $'\n'\
"TAKIPI_BASE_URL=$takipi_base_url" $'\n'\
"TAKIPI_NATIVE_LIBRARIES=$takipi_native_libraries" $'\n'\
"DAEMON=$daemon" $'\n'\
"TAKIPI_INSTALLATION_TIME=$(($(date +%s%N)/1000))" $'\n'\
"JVM_LIB_FILE=$jvm_lib_file" $'\n'\
"TAKIPI_MACHINE_NAME=$machine_name" $'\n'\
"$proxy" $'\n'\
> $takipi_default_file
}

function save_takipi_config_file()
{
	proxy=""

	if [ "$takipi_https_proxy" != "" ]; then
		proxy="httpsProxy=$takipi_https_proxy"
	fi

# The echo lines are not indented on purpose 
	echo \
"takipiHome=$takipi_home" $'\n'\
"baseUrl=$takipi_base_url" $'\n'\
"libraryPath=$takipi_native_libraries" $'\n'\
"installTime=$(($(date +%s%N)/1000))" $'\n'\
"jvmPath=$jvm_lib_file" $'\n'\
"serverName=$machine_name" $'\n'\
"ideAttach=$ide_attach" $'\n'\
"autoUpdate=$auto_update" $'\n'\
"serviceId=$service_id" $'\n'\
"listenOnPort=$listen_on_port" $'\n'\
"masterHost=$daemon_host" $'\n'\
"masterPort=$daemon_port" $'\n'\
"passphrase=$aos_passphrase" $'\n'\
"javaHeapSize=$java_heap_size" $'\n'\
"$proxy" $'\n'\
> $takipi_config_file
}

function setup_secret_key()
{
	if [ "$takipi_secret_key" != "" ]; then
		echo $takipi_secret_key > $takipi_home/work/secret.key
		chmod 600 $takipi_home/work/secret.key

		setup_service_id
	fi
}

function detect_running_jvm_processes()
{
	detectSubset=false

	if [ $# != 0 ]; then
		detectSubset=$1
		previousSet=( ${java_process[@]} )
	fi

	pids=($(ps -e -o pid | tail -n +2))
	java_process=()

	for i in "${pids[@]}"
	do
		cat /proc/$i/maps 2>&1 | grep libjvm.so >/dev/null 2>&1
		detectJvmReturnCode=$?
		cat /proc/$i/maps 2>&1 | grep libTakipiAgent.so >/dev/null 2>&1
		detectTakipiReturnCode=$?

		if [ "$detectJvmReturnCode" = "0" -a "$detectTakipiReturnCode" != "0"  ]; then
			ps -e | grep $i | grep "takipi-service" >/dev/null 2>&1
			if [ $? != 0 ]; then
				java_process+=($i)
			fi
		fi 
	done

	if [ "$detectSubset" == true ]; then
		tmp=()

		for newpid in "${java_process[@]}"
		do 
			for oldpid in "${previousSet[@]}"
			do 
				if [ "$oldpid" == "$newpid" ]; then
					tmp+=($oldpid)
				fi
			done
		done

		java_process=( ${tmp[@]} )
	fi
}

function show_running_javas()
{
	detect_running_jvm_processes

	if [ ${#java_process[@]} != 0 ]; then
		color='\e[1;38;5;208;48;5;232m'
		link_color='\e[49;96m'
		arg_color='\e[4m'
		clear_color='\E[00m'
		echo -e "${color}Please restart the following Java processes with the ${arg_color}-agentlib:TakipiAgent${clear_color}${color} argument:${clear_color}"

		echo ""
		print_running_java_processes
		echo ""
		read -t30 -n1 -rsp $'After restarting, press any key to continue.\n' < /dev/tty
		echo ""

		detect_running_jvm_processes true

		if [ ${#java_process[@]} != 0 ]; then
			echo -e "${color}WARNING:${clear_color} The following Java processes still require a restart with the ${arg_color}-agentlib:TakipiAgent${clear_color} argument for Takipi to monitor them:"
			echo ""
			print_running_java_processes 
		fi
	else
		color='\e[1;38;5;208;48;5;232m'
		link_color='\e[49;96m'
		clear_color='\E[00m'
		echo -e "${color}Please restart any JVMs currently running on your machine${clear_color}"
	fi
}

function print_running_java_processes()
{
	if [ ${#java_process[@]} == 0 ]; then
		return
	fi

	clear_style='\E[00m'
	style='\E[1m\E[4m'

	printf "    ${style}PID${clear_style}%-7s${style}Application${clear_style}\n" ""

	pids_str=$(echo "${java_process[*]}" | sed 's/ /,/g')
	procs=$(ps -p $pids_str -o pid,args |  tail -n +2 )
	
	echo "$procs" | awk \
		' {
			if ($2 !~ /java.?$/)
			{
				# non standard java process.
				printf "    %-10s%s \n", $1, $2;	
				next;
			}
			
			skipNext = "false";
			marked = "false"

			for (i = 3; i <= NF; i++)
			{
				if (skipNext == "true")
				{
					skipNext = "false";
					continue;
				}

				if ($i == "-jar")
				{
					nextIdx = i + 1;
					printf "    %-10s%s \n", $1, $nextIdx;
					marked = "true";
					break;
				}

				if ($i !~ /^-/)
				{
					printf "    %-10s%s \n", $1, $i;
					marked = "true";
					break;
				}

				if ($i == "-cp" || $i == "-classpath")
				{
					skipNext = "true";
				}
			}

			if (marked == "false")
			{
				printf "    %-10s%s \n", $1, $2;
			}
		} '
}

function remove_agent_links()
{
	LIB_DIRS="/usr/lib /usr/lib32 /usr/lib64 /lib /lib32 /lib64"

	# Look for the right JVM to use
	for libDir in $LIB_DIRS; do
		if [ -f "$libDir/libTakipiAgent.so" ]; then
			rm -f "$libDir/libTakipiAgent.so" >/dev/null 2>&1
		fi
	done
	
	cp -f $takipi_home/lib32/libTakipiAgent.so $lib32_dir/libTakipiAgent.so >/dev/null 2>&1
	cp -f $takipi_home/lib/libTakipiAgentEmpty.so $lib64_dir/libTakipiAgent.so >/dev/null 2>&1

	ldconfig >/dev/null 2>&1
	/sbin/ldconfig >/dev/null 2>&1
}

function remote_logs()
{
	if [ ! -r $takipi_bootstrap_jar ]; then
		log "No takipi-bootstrap found"
		return 0
	fi

	look_for_java

	if [ ! -x "$java_exe" ]; then
		log "No java found"
		return 0
	fi

	$java_exe -cp $takipi_bootstrap_jar m.M remotelogs $takipi_secret_key $takipi_home $takipi_base_url uninstall
}

function remove_secret_key()
{
	if [ -f $takipi_home/work/secret.key ]; then
		echo -n "Your secret key is: " && cat $takipi_home/work/secret.key
		echo ""
		echo "The secret key file is also being deleted."

		takipi_secret_key=`cat $takipi_home/work/secret.key`
		service_id=(${takipi_secret_key//#/ })
	else
		echo "The secret key file is unavailable."
	fi
}

function remove_takipi_home()
{
	echo "About to remove Takipi files..."
	
	rm -rf $takipi_home >/dev/null 2>&1
}

function remove_takipi_daemon()
{
	rm -rf /etc/takipi >/dev/null 2>&1
	rm -rf /etc/init.d/takipi >/dev/null 2>&1
	rm -rf /lib/systemd/system/takipi.service >/dev/null 2>&1
	rm -rf /etc/ld.so.conf.d/takipi.conf >/dev/null 2>&1
	rm -rf $takipi_default_file >/dev/null 2>&1
	rm -rf /etc/init/takipi.conf >/dev/null 2>&1

	# sysvinit / Ubuntu
	/usr/sbin/update-rc.d -f takipi remove >/dev/null 2>&1

	# sysvinit / Gentoo / Alpine
	/sbin/rc-update del takipi default >/dev/null 2>&1

	# sysvinit / RedHat
	/sbin/chkconfig takipi off >/dev/null 2>&1

	# sysvinit/ SuSE
	/sbin/insserv -r takipi >/dev/null 2>&1

	# systemd
	systemctl disable takipi >/dev/null 2>&1
	systemctl daemon-reload >/dev/null 2>&1
}

function uninstall()
{
	remove_secret_key
	uninstall_auto_agent
	do_smart_detach
	remote_logs
	remove_agent_links
	remove_takipi_home
	remove_takipi_daemon

	ldconfig >/dev/null 2>&1
	/sbin/ldconfig >/dev/null 2>&1
}

function uninstall_aos()
{
	uninstall_auto_agent
	do_smart_detach
	remove_agent_links
	remove_takipi_home
}

function start_service()
{
	should_report=$1

	log "About to start Takipi ($init_type, $os_name)..."

	if [ "$init_type" == "upstart" ]; then
		initctl start takipi >/dev/null 2>&1
	elif [ "$init_type" == "systemd" ]; then
		systemctl start takipi.service >/dev/null 2>&1
	elif [ "$init_type" == "openrc" ]; then
		rc-service takipi start >/dev/null 2>&1
	else 
		/etc/init.d/takipi start >/dev/null 2>&1
	fi

	start_result=$?

	if [ $should_report -eq "1" ]; then
		if [ $start_result -eq "0" ]; then
			report_install_status 62
		else
			report_install_status 9 "$start_result"
		fi
	fi

	return $start_result
}

function start_takipi()
{
	if [ "$start_daemon" == "0" ]; then
		return 0
	fi

	start_service 0

	init_error_code=$?

	if [ "$init_error_code" != "0" ]; then
		echo "Problem starting Takipi."

		report_install_status 9 "$init_error_code"
		return 1
	fi

	report_install_status 62

	log "Takipi started successfully."
	return 0
}

function show_restart_vms_message()
{
	echo ""
	echo "Takipi will now attach to new Java processes."
	echo ""

	if [ "$interactive_mode" == "1" ]; then
		show_running_javas
	fi

	if [ "$is_from_oneliner" = "0" ]; then
		echo ""
		echo -n "To use in the current shell(s) "

		echo -e '\E[33;40m\033[1m'"run: 'source $takipi_home/etc/takipi-auto-agent', or restart the shell.\033[0m"
		tput sgr0
	fi
}

function stop_takipi()
{
	log "Stopping the Takipi daemon (if running)..."

	systemctl stop takipi.service >/dev/null 2>&1
	/etc/init.d/takipi stop >/dev/null 2>&1
	initctl stop takipi >/dev/null 2>&1
	rc-service takipi stop >/dev/null 2>&1

	daemon_pid=`processPid takipi-service`

	if [ -n "$daemon_pid" ]; then
		kill -9 $daemon_pid
	fi
}

function setup_smart_attach()
{
	if [ "$smart_attach" == "1" ]; then
		
		if ! do_smart_attach; then
			return 1
		fi

		echo "Successfully enabled config attach"
	else

		if ! do_smart_detach; then
			return 1
		fi

		echo "Successfully disabled config attach"
	fi

	return 0
}

function setup_auto_attach()
{
	if [ "$auto_agent" == "1" ]; then

		if ! install_auto_agent; then
			return 1
		fi

		echo "Successfully enabled auto attach"

	else

		if ! uninstall_auto_agent; then
			return 1
		fi

		echo "Successfully disabled auto attach"
	fi

	return 0
}

function setup_service_id()
{
	new_service_id=$service_id

	load_takipi_default_file "1"
	load_takipi_config_file "1"

	service_id=$new_service_id

	save_takipi_default_file
	save_takipi_config_file
}

function setup_machine_name()
{
	new_machine_name=$machine_name

	load_takipi_default_file "1"
	load_takipi_config_file "1"

	machine_name=$new_machine_name

	save_takipi_default_file
	save_takipi_config_file
}

function setup_proxy()
{
	new_proxy=$takipi_https_proxy

	load_takipi_default_file "1"
	load_takipi_config_file "1"

	takipi_https_proxy=$new_proxy

	save_takipi_default_file
	save_takipi_config_file
}

function setup_listen_on_port()
{
	new_listen_on_port=$listen_on_port
	new_aos_passphrase=$aos_passphrase

	load_takipi_default_file "1"
	load_takipi_config_file "1"

	listen_on_port=$new_listen_on_port
	
	if [ -n "$new_aos_passphrase" ]; then
		aos_passphrase=$new_aos_passphrase
	fi

	save_takipi_default_file
	save_takipi_config_file
}

function setup_daemon_host()
{
	new_daemon_host=$daemon_host
	new_daemon_port=$daemon_port
	new_aos_passphrase=$aos_passphrase

	load_takipi_default_file "1"
	load_takipi_config_file "1"

	daemon_host=$new_daemon_host

	if [ -n "$new_daemon_port" ]; then
		daemon_port=$new_daemon_port
	fi

	if [ -n "$new_aos_passphrase" ]; then
		aos_passphrase=$new_aos_passphrase
	fi

	if [ "$is_aos_mode" == "1" ]; then
		if [ -z "daemon_host" -o -z "daemon_port" ]; then
			echo "Please provide a valid host name and port for the remote service"
			return 1
		fi
	fi

	save_takipi_default_file
	save_takipi_config_file
}

function setup_ide_attach()
{
	new_ide_attach=$ide_attach

	load_takipi_default_file "1"
	load_takipi_config_file "1"

	ide_attach=$new_ide_attach

	save_takipi_default_file
	save_takipi_config_file
}

function setup_auto_update()
{
	new_auto_update=$auto_update

	load_takipi_default_file "1"
	load_takipi_config_file "1"

	auto_update=$new_auto_update

	save_takipi_default_file
	save_takipi_config_file
}

function url_encode_string()
{
	local url="$1"
	local urlLen=${#url}
	local encoded=""

	for (( i=0 ; i < urlLen ; i++ )); do
		curChar=${url:$i:1}
		case "$curChar" in
			[-_.~a-zA-Z0-9])
				o="${curChar}"
				;;
			*)
				printf -v o '%%%02x' "'$curChar"
				;;
     	esac
		encoded+="${o}"
	done

	url_encode_result="$encoded"
}

function report_install_status()
{
	if [ "$TAKIPI_DISABLE_REPORT_STATUS" == "1" ]; then
		return 0
	fi
	
	local status=$1

	url_encode_string "$2"
	extra_str=$url_encode_result

	url=""

	if [ $status -ne 8 ]; then
		url="${takipi_base_url}service/ir?sid=$service_id&status=$status&os=nix&es=$extra_str"
	else
		url="${takipi_base_url}service/ir?status=$status&os=nix&kp=$service_id&es=$extra_str"
	fi

	download $url /dev/null "2" "5"
	
	return 0
}

function usage()
{
	if [ "$skip_usage" = "1" ]; then
		return 0
	fi

	echo "usage: $SCRIPTNAME {-i|-u|--install|--uninstall} [-v|--verbose] [--sk|--secret_key=<value>] [--machine_name=<value>] [--https_proxy[=]<value>] [-d|--default_location]" >&2
}

function show_final_installation_message()
{
	link_color='\e[49;96m'
	clear_color='\E[00m'

	echo " "
	space="                          "
	echo 	"***************************************************************************************"
	echo -e "* Head over to ${link_color}https://app.takipi.com${clear_color} to start using Takipi.$space*" 
	echo 	"***************************************************************************************"
	echo " "
}

function run_commands()
{
	if [ "$do_fpm_install" == "1" ]; then

		if [ -z "$takipi_secret_key" -a -r "$takipi_home/work/secret.key" ]; then
			takipi_secret_key=`cat $takipi_home/work/secret.key` >/dev/null 2>&1
			service_id=(${takipi_secret_key//#/ })
		fi
		
		if [ -z "$takipi_secret_key" ]; then
			do_install="1"
		fi
		
		echo "$takipi_secret_key" | grep "^S[1-9][0-9]*#[^#][^#]*#[^#][^#]*#[0-9A-Fa-f]\{4\}$" > /dev/null 2>&1
		
		if [ $? -ne 0 ]; then
			do_install="1"
		fi
		
		if [ "$do_install" == "1" ]; then
			start_daemon="0"
		else
			do_reinstall="1"
		fi
	fi

	if [ "$do_install" = "1" ]; then
		
		if [ "$do_install_jdk" = "1" ]; then
			if ! install_jdk; then
				exit 1
			fi
		fi

		if [ is_reinstall == "1" ]; then
			report_install_status 40 "$os_name, `uname -a`"
		else
			report_install_status 41 "$os_name, `uname -a`"
		fi

		report_install_status 21

		if [ "$is_aos_mode" == "1" ]; then
			if ! install_takipi_aos; then
				exit 1
			fi
			
			if ! install_agent; then
				exit 1
			fi
		else
			if ! install_takipi; then
				exit 1
			fi

			if ! install_agent; then
				exit 1
			fi

			if ! start_takipi; then
				exit 1
			fi
		fi

		report_install_status 22

		if [ "$auto_agent" == "1" ]; then
			show_restart_vms_message
		fi

		if [ "`type -t after_install`" == "function" ]; then
			after_install
		fi
		
	elif [ "$do_uninstall" = "1" ]; then

		report_install_status 31

		if [ "$is_aos_mode" == "1" ]; then
			if ! uninstall_aos; then
				log "Error uninstalling takipi"
				exit 1
			fi
		else
			rm -rf $takipi_home/bin/takipi-service >/dev/null 2>&1

			if ! stop_takipi; then
				log "Error stopping daemon."
			fi

			if ! uninstall; then
				log "Error uninstalling takipi"
				exit 1
			fi
		fi

		report_install_status 32

		echo ""
		echo "Takipi uninstalled successfully."
		echo "Please restart your shell."
		echo ""

	elif [ "$do_reinstall" = "1" ]; then

		stop_takipi
		choose_init_type
		configure_init 1
		start_takipi
	
	elif [ "$do_setup_secret_key" = "1" ]; then

		if ! setup_secret_key; then
			log "Error setting up secret key"
			exit 1
		fi

		echo "Secret key successfully changed to: $takipi_secret_key"

	elif [ "$do_setup_machine_name" = "1" ]; then

		if ! setup_machine_name; then
			log "Error setting up machine name"
			exit 1
		fi

		echo "Machine name successfully changed to: \"$machine_name\""

	elif [ "$do_setup_proxy" = "1" ]; then

		if ! setup_proxy; then
			log "Error setting up proxy"
			exit 1
		fi

		echo "Proxy successfully changed to: $takipi_https_proxy"

	elif [ "$do_setup_listen_on_port" = "1" ]; then

		if ! setup_listen_on_port; then
			log "Error setting up remote"
			exit 1
		fi

		echo "Service successfully configured to listen on: $listen_on_port"

	elif [ "$do_setup_daemon_host" = "1" ]; then

		if ! setup_daemon_host; then
			log "Error setting up remote service"
			exit 1
		fi

		echo "Agent successfully connect to: $daemon_host:$daemon_port"
		
	elif [ "$do_setup_smart_attach" = "1" ]; then

		if ! setup_smart_attach; then
			log "Error setting up config attach"
			exit 1
		fi
	
	elif [ "$do_setup_auto_attach" = "1" ]; then

		if ! setup_auto_attach; then
			log "Error setting up auto attach"
			exit 1
		fi

	elif [ "$do_setup_ide_attach" = "1" ]; then

		if ! setup_ide_attach; then
			log "Error setting up ide attach"
			exit 1
		fi

	elif [ "$do_setup_auto_update" = "1" ]; then

		if ! setup_auto_update; then
			log "Error setting up auto updates"
			exit 1
		fi

	elif [ "$do_start_service" = "1" ]; then

		choose_init_type
		configure_init 1
		start_service 1

		if [ $? -ne "0" ]; then
			log "Error starting the Takipi daemon"
			exit 1
		fi
	elif [ "$do_stop_service" = "1" ]; then
		
		if ! stop_takipi; then
			log "Error stopping daemon."
			exit 1
		fi
	fi
}

function main()
{
	if [ -n "$JAVA_TOOL_OPTIONS" ]; then
		java_tool_options_backup="$JAVA_TOOL_OPTIONS"
		unset JAVA_TOOL_OPTIONS
	fi

	if ! init "$@"; then
		return 1
	fi

	if ! validate; then
		return 1
	fi

	report_install_status 11
	report_install_status 60 "$machine_arch"

	run_commands "$@"

	report_install_status 12

	if [ -n "$java_tool_options_backup" ]; then
		JAVA_TOOL_OPTIONS="$java_tool_options_backup"
		export JAVA_TOOL_OPTIONS
	fi
}


check_connection="1"
start_daemon="0"

function after_install()
{
	show_final_installation_message
}

main "$@"
