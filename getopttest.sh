#!/bin/bash

# ?a? and ?arga? have optional arguments with default values.
# ?b? and ?argb? have no arguments, acting as sort of a flag.
# ?c? and ?argc? have required arguments.

# set an initial value for the flag
ARG_B=0

# read the options
TEMP=`getopt -o a::t:i::o:: --long action::,type:,source-dir::,input:: -- "$@"`
eval set -- "$TEMP"

# extract options and their arguments into variables.
while true ; do
    case "$1" in
        -a|--action)
            case "$2" in
                "") action='genproj' ; shift 2 ;;
                *) action=$2 ; shift 2 ;;
            esac ;;
        -t|--type)
            case "$2" in
                "") prjtype='genproj' ; shift 2 ;;
                *) prjtype=$2 ; shift 2 ;;
            esac ;;
        -i|--input)
            case "$2" in
                "") shift 2 ; shift 2 ;;
                *) input=$2 ; shift 2 ;;
            esac ;;
        -o|--output)
            case "$2" in
                "") shift 2 ; shift 2 ;;
                *) output=$2 ; shift 2 ;;
            esac ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

# do something with the variables -- in this case the lamest possible one :-)
echo "ARG_A = $action"
echo "ARG_B = $input"
echo "ARG_C = $output"
echo "ARG_C = $prjtype"
