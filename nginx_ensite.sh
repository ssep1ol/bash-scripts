#!/usr/bin/env bash

### nginx_ensite --- Bash script to enable or disable a site in nginx.

### Copyright (C) 2010, 2015 António P. P. Almeida <appa@perusio.net>

### Author: António P. P. Almeida <appa@perusio.net>

### Permission is hereby granted, free of charge, to any person obtaining a
### copy of this software and associated documentation files (the "Software"),
### to deal in the Software without restriction, including without limitation
### the rights to use, copy, modify, merge, publish, distribute, sublicense,
### and/or sell copies of the Software, and to permit persons to whom the
### Software is furnished to do so, subject to the following conditions:

### The above copyright notice and this permission notice shall be included in
### all copies or substantial portions of the Software.

### Except as contained in this notice, the name(s) of the above copyright
### holders shall not be used in advertising or otherwise to promote the sale,
### use or other dealings in this Software without prior written authorization.

### THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
### IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
### FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
### THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
### LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
### FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
### DEALINGS IN THE SOFTWARE.

SCRIPTNAME=${0##*/}

## The nginx binary. Check if we're root or not. If we are get the
## path to nginx.  If not hardcode the path.
if [ $(id -u) -eq 0 ]; then
    IS_ROOT=1
    NGINX=$(command -v nginx) || exit 1
else
    STATUS=0
    NGINX=/usr/sbin/nginx
fi

## Default value for the configuration directory.
NGINX_CONF_DIR=/etc/nginx

function print_usage() {
    echo "$SCRIPTNAME [-c <nginx configuration base directory> default: /etc/nginx] [ -s <startup program name> default: service nginx reload] <site name>"
}

## Extract the startup program name from a given argument. If it's a
## path to nginx then add the '-s reload' to the name. Otherwise just
## return the given argument.
## $1: the program name.
## Returns the proper startup program name,
function get_startup_program_name() {
    local value="$1"
    if [[ $1 =~ [[:alnum:]/-]]+nginx$ ]]; then
        value="$1 -s reload"
    elif [ -z "$1" ]; then
        value="service nginx reload"
    else
        value=$1
    fi
    echo "$value"
}

## The default start up program is service.
STARTUP_PROGRAM_NAME=$(get_startup_program_name)

## Create the relative path to the vhost file.
## $1: configuration file name (usually the vhost)
## $2: available sites directory name (usually sites-available)
## Returns the relative path from the sites-enabled directory.
function make_relative_path() {
    printf '../%.0s%s/%s' $(eval echo {0..$(expr length "${1//[^\/]/}")}) $2 $1
}

## Checking the type of action we will perform. Enabling or disabling.
ACTION=$(echo $SCRIPTNAME | awk '$0 ~ /dissite/ {print "DISABLE"} $0 ~ /ensite/ {print "ENABLE"} $0 !~ /(dis|en)site/ {print "UNKNOWN"}')

if [ "$ACTION" == "UNKNOWN" ]; then
    echo "$SCRIPTNAME: Unknown action!" >&2
    print_usage
    exit 2
fi

## Check the number of arguments.
if [ $# -lt 1 -o $# -gt 5 ]; then
    print_usage >&2
    exit 3
fi

## Parse the getops arguments.
while getopts c:s: OPT; do
    case $OPT in
        c|+c)
            NGINX_CONF_DIR=$(realpath "$OPTARG")
            if [[ ! -d $NGINX_CONF_DIR ]]; then
                echo "$NGINX_CONF_DIR directory not found." >&2
                exit 3
            fi
            ;;
        s|+s)
            STARTUP_PROGRAM_NAME=$(get_startup_program_name "$OPTARG")
            ;;
        *)
            print_usage >&2
            exit 4
            ;;
    esac
done
shift $(( OPTIND - 1 ))
OPTIND=1

## The paths for both nginx configuration files and the sites
## configuration files and symbolic link destinations.
AVAILABLE_SITES_PATH="$NGINX_CONF_DIR/sites-available"
ENABLED_SITES_PATH="$NGINX_CONF_DIR/sites-enabled"

## Check the number of arguments.
if [ $# -ne 1 ]; then
    print_usage >&2
    exit 3
else
    SITE_AVAILABLE=$(make_relative_path "$1" ${AVAILABLE_SITES_PATH##*/})

    ## If enabling the 'default' site then make sure that it's the
    ## first to be loaded.
    if [ $1 == "default" ]; then
        SITE_ENABLED="$ENABLED_SITES_PATH/default"
    else
        SITE_ENABLED="$ENABLED_SITES_PATH/$1"
    fi
    ## Check if the directory where we will place the symlink
    ## exists. If not create it.
    [ -d ${SITE_ENABLED%/*} ] || mkdir -p ${SITE_ENABLED%/*}
fi

## Check that the file corresponding to site exists if enabling or
## that the symbolic link exists if disabling. Perform the desired
## action if possible. If not signal an error and exit.
case $ACTION in
    ENABLE)
        # Change to the directory where we will place the symlink so that we
        # see the relative path correctly.
        cd "${SITE_ENABLED%/*}";
        if [ -r $SITE_AVAILABLE ]; then
            ## Test for a well formed configuration only when we are
            ## root.
            if [ -n "$IS_ROOT" ]; then
                echo "Pre-flight check..."
                $NGINX -t
                STATUS=$?
            fi
            if [ $STATUS -ne 0 ]; then
                exit 5
            fi
            ## Check the config testing status and if the link exists already.
            if [ -h $SITE_ENABLED ]; then
                ## If already enabled say it and exit.
                echo "$1 is already enabled."
                exit 0
            fi
            ln -s $SITE_AVAILABLE $SITE_ENABLED
            if [ -n "$IS_ROOT" ]; then
                echo "New config check..."
                $NGINX -t
                STATUS=$?
            fi
            if [ $STATUS -eq 0 ]; then
                echo "Site $1 has been enabled."
                # printf '\nRun "%s" to apply the changes.\n' $STARTUP_PROGRAM_NAME
                echo "Run '$STARTUP_PROGRAM_NAME' to apply the changes."
                exit 0
            else
                rm $SITE_ENABLED
                echo "$1 not enabled"
                exit 5
            fi
        else
            echo "Site configuration file $1 not found." >&2
            exit 6
        fi

        ;;
    DISABLE)
        if [ "$1" = "default" ] ; then
            if [ -h "$ENABLED_SITES_PATH/default" ] ; then
                SITE_ENABLED="$ENABLED_SITES_PATH/default"
            fi
        fi
        if [ -h $SITE_ENABLED ]; then
            rm $SITE_ENABLED
            echo "Site $1 has been disabled."
            # printf '\nRun "%s" to apply the changes.\n' $STARTUP_PROGRAM_NAME
            echo "Run '$STARTUP_PROGRAM_NAME' to apply the changes."
            exit 0
        else
            echo "Site $1 doesn't exist." >&2
            exit 7
        fi
        ;;
esac
