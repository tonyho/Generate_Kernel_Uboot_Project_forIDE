#! /bin/bash

#Err Macro
SUCCESS=0
ERR_BUILD_BOARD=1 
ERR_EXIST_DIR=2 
ERR_NO_CFG=3
ERR_TAGFILE_NOT_FOUND=4
ERR_FILE_NOT_EXIST=5
ERR_VERSION_MISMATCH=6
ERR_PROGRAM_PARA=7
ERR_TOOLKIT=8
ERR_CHECK_CONFIG=9
ERR_NO_TARGET_RELEASE=10
ERR_FILE_ALREADY_EXIST=11
ERR_NOT_EXIST=12
ERR_CMD_NOT_FOUNT=13

# Color used in echo
## Text--forground
Echo_Black_Text=`tput setaf 0`
Echo_Red_Text=`tput setaf 1`
Echo_Green_Text=`tput setaf 2`
Echo_Yellow_Text=`tput setaf 3`
Echo_Blue_Text=`tput setaf 4`
Echo_Magenta_Text=`tput setaf 5`
Echo_Cyan_Text=`tput setaf 6`
Echo_White_Text=`tput setaf 7`
Echo_Color_Reset=`tput sgr0`
## background color
Echo_Black_BG=`tput setab 0`
Echo_Red_BG=`tput setab 1`
Echo_Green_BG=`tput setab 2`
Echo_Yellow_BG=`tput setab 3`
Echo_Blue_BG=`tput setab 4`
Echo_Magenta_BG=`tput setab 5`
Echo_Cyan_BG=`tput setab 6`
Echo_White_BG=`tput setab 7`
Echo_Color_Reset=`tput sgr0`

print_help()
{
    echo "Usage: "
    ##              $0                                  $1                          $2
    ##                                                  dir_to_be_count             result_dir 
    echo "       ${Echo_Green_Text}`basename $0`  <Directory to be count> <result output directory>${Echo_Color_Reset}"
	echo "       `basename $0` --help/-h"
	echo
	echo "For example:"
    echo -e " \t `basename $0` kernel-ZZZ kernelResult"
    echo -e " \t    this would count the valid source code line number of kernel source in kernel-ZZZ, the result would output to kernelResult"
    echo 
    echo -e " \t `basename $0` uboot-ZZZ ubootResult"
    echo -e " \t    this would count the valid source code line number of uboot source in uboot-ZZZ, the result would be in ubootResult"
}

if [ $1 = "-h" -o $1 = "--help" ]; then
    print_help
    exit 0
fi

DIR_TO_BE_COUNT=$1
cd "${DIR_TO_BE_COUNT}"  >/dev/null
REALPATH_DIR_TO_BE_COUNT="${PWD}"
cd - >/dev/null
REALPATH_DIR_TO_BE_COUNT="${REALPATH_DIR_TO_BE_COUNT}""/"
RESULT_PRJ=$2

Gen_Tmp="Gen_Tmp"
if [ -d "${Gen_Tmp}" ] ; then
    echo "${Gen_Tmp} already existed"
else
    mkdir "${Gen_Tmp}"
fi
HeadFileList_All="${Gen_Tmp}"/"HF_All.txt"
HF_NoHost="${Gen_Tmp}"/"HF_NoHost.txt"
HF_NoHost_ND="${Gen_Tmp}"/"HF_NoHost_ND.txt"
HF_AbPath="${Gen_Tmp}"/"HF_AbosultePath.txt"
HF_AbsPath_ND="${Gen_Tmp}"/"HF_AbosultePath_ND.txt"
HF_RelPath="${Gen_Tmp}"/"HF_RelPath.txt"
HF_RelPath_ND="${Gen_Tmp}"/"HF_RelPath_ND.txt"
NotFound="${Gen_Tmp}"/"NotFound.txt"
NotFound_TT="${Gen_Tmp}"/"NotFound_Type2.txt"
Valid_HF="${Gen_Tmp}"/"Valid_HF.txt"
VALID_SRC="${Gen_Tmp}"/"Valid_SRC.txt"
NotFound_Verified="${Gen_Tmp}"/"NotFOund_Valid.txt"
HF_NoPath="${Gen_Tmp}"/"HF_NoPath.txt"
HF_NoPath_ND="${Gen_Tmp}"/"HF_NoPath_ND.txt"
##Source code type: UBOOT KERNEL UNKNOWN
SOURCE_CODE_TYPE=

echo -e "${Echo_Yellow_BG}"
echo -e "${Echo_Color_Reset}"
yes '-' | head -n$(tput cols) | tr -d '\n'
## Check the output directory whether is exist
if [ ! -d "${RESULT_PRJ}" ]; then
    mkdir "${RESULT_PRJ}"
else
    echo "${Echo_Red_Text}Direcotry $RESULT_PRJ already exist${Echo_Color_Reset}"
    exit ${ERR_EXIST_DIR}
fi

## Check the source code directory whether is exist
if [ ! -d "${DIR_TO_BE_COUNT}" ]; then # Not found
    echo "${Echo_Red_Text}Direcotry $DIR_TO_BE_COUNT NOT exist${Echo_Color_Reset}"
    exit ${ERR_NOT_EXIST}
fi

U_BOOT_ID_FILE=u-boot
KERNEL_ID_FILE=vmlinux
DotConfig=".config"

## Check the source code type: u-boot or kernel
if [ ! -e "${DIR_TO_BE_COUNT}"/"${U_BOOT_ID_FILE}" -a -e "${DIR_TO_BE_COUNT}"/"${KERNEL_ID_FILE}" ]; then
    #echo "${Echo_Green_Text} ${DIR_TO_BE_COUNT} source code type is: kernel${Echo_Color_Reset}"
    echo "Source code type is: [${Echo_Green_Text}kernel${Echo_Color_Reset}]"
    SOURCE_CODE_TYPE="KERNEL"
elif [ -e "${DIR_TO_BE_COUNT}"/"${U_BOOT_ID_FILE}" -a -e "${DIR_TO_BE_COUNT}"/"${U_BOOT_ID_FILE}" ]; then
    echo "Source code type is: [${Echo_Green_Text}u-boot${Echo_Color_Reset}]"
    SOURCE_CODE_TYPE="UBOOT"
else
    echo "Source code type is: [${Echo_Red_Text}UNKNOWN${Echo_Color_Reset}]"
    SOURCE_CODE_TYPE="UNKNOWN"
    #exit $ERR_FILE_NOT_EXIST
fi
if [ -e "${DIR_TO_BE_COUNT}"/"${DotConfig}" -a "UBOOT" == "${SOURCE_CODE_TYPE}" ]; then
    echo "U-boot: [${Echo_Green_Text}has .config${Echo_Color_Reset}]"
    SOURCE_CODE_TYPE="UBOOT_WITH_DOTCONFIG"
elif [ ! -e "${DIR_TO_BE_COUNT}"/"${DotConfig}" -a "UBOOT" == "${SOURCE_CODE_TYPE}" ]; then
    echo "U-boot: [${Echo_Green_Text}without .config${Echo_Color_Reset}]"
fi

if [ "${SOURCE_CODE_TYPE}" == "UBOOT_WITH_DOTCONFIG" -o "${SOURCE_CODE_TYPE}" == "KERNEL" ]; then
    KERNEL_SRC_WORK_DIR=kernel_src_work_dir
    KERNEL_HEADER_WORK_DIR=kernel_valid_header_files

    KERNEL_VALID_HEADER_FILES=

    # Get kernel version
    VER=`head -n 3 ${DIR_TO_BE_COUNT}/Makefile | awk -F'=' '{print $2}'`
    KERN_VERSION=`echo ${VER} | awk '{print $1}'`
    KERN_PATCHLEVEL=`echo ${VER} | awk '{print $2}'`
    KERN_SUBLEVEL=`echo ${VER} | awk '{print $3}'`

    #echo VER=${VER}
    #echo VERSION=[${KERN_VERSION}], KERN_PATCHLEVEL=[${KERN_PATCHLEVEL}], KERN_SUBLEVEL=[${KERN_SUBLEVEL}]
    # the source file used to be compiled (.S .s .c)
    KERNEL_VALID_SRC_FILES=

    KERNEL_VALID_SRC_FILES=`find "${DIR_TO_BE_COUNT}" ! -path "./tools/*"  ! -path "./examples/*" \
        ! -path \*/.built-in.o.cmd -name '.*.o.cmd' -print0 |  xargs -0 egrep ":=[[:space:]]+[[:alnum:]]+" \
        | grep -v '\-gcc' | grep -v  '\-ld' | grep -v ' := gcc'  | grep -v ' := g++' \
        | awk -F':=' '{print $2}' | grep -v 'scripts' | grep -v 'tools'`

    if [ -z "${KERNEL_VALID_SRC_FILES}" ] ; then
        echo "${Echo_Red_Text}Old kernel found! kernel version=[${KERN_VERSION}.${KERN_PATCHLEVEL}.${KERN_SUBLEVEL}]${Echo_Color_Reset}"
        KERNEL_VALID_SRC_FILES=`find "${DIR_TO_BE_COUNT}" ! -path "./tools/*"  ! -path "./examples/*" \
            ! -path \*/.built-in.o.cmd -name '.*.o.cmd' -print0 | xargs -0 egrep ":=[[:space:]]+[[:alnum:]]+" \
            |  awk '{print $NF}' | sed '/^.*.o$/d' | sed '/--end-group/d'`
    fi

    #######################################################################
    # .S .c .s source file list
    #######################################################################

    ## copy the valid files
    # file not found in dir_to_be_count
    File_Not_Exist=
    Index=0
    for files in `echo "${KERNEL_VALID_SRC_FILES}" | sed -e 's/\ /\n/g'`; do
        DIR_OF_FILES=`dirname "${files}"`
        #echo "${KERNEL_VALID_SRC_FILES}"  dirnames=${DIR_OF_FILES}
        if [ ! -e "${DIR_TO_BE_COUNT}"/"${files}" ]; then
            File_Not_Exist+="${DIR_TO_BE_COUNT}"/"${files}" 
            File_Not_Exist+=" "
            #echo "File not found: ${Echo_Red_Text}"${DIR_TO_BE_COUNT}"/"${files}" ${Echo_Color_Reset}"
            continue
        fi
        echo "${files}" >> "${VALID_SRC}"
        ((Index++))
        echo -e -n "\rSource file[.c .S .s] Index:\t"
        echo -e -n "[${Echo_Cyan_Text}${Index}${Echo_Color_Reset}]"
    done

    if [ -n "${File_Not_Exist}" ]; then
        #echo "${Echo_Red_Text}Some files not found, please check:${Echo_Color_Reset}"
        echo "${File_Not_Exist}" | sed -e 's/\ /\n/g' 
    fi

    #######################################################################
    # .h header file copy
    #######################################################################

    # file not found in dir_to_be_count
    File_Not_Exist=
    Index=0

    # Find all the header files, include the host PCs, which is start with /usr
    find "${DIR_TO_BE_COUNT}" -name .*.o.cmd  -print0 | xargs -0 grep '\.h' | awk '{for(i=2;i<=NF;i++){printf "%s ", $i}; printf "\n"}' \
        | grep -v ':=' | sed -e 's/\$.*include/include/g' -e 's/\.h.*$/\.h/g' > "${HeadFileList_All}"
    # Exclude the hostPCs header file. remain the toolchain libc header, linux kernel headerfiles
    grep -v '^\/usr' "${HeadFileList_All}" > "${HF_NoHost}"
    awk '!seen[$0]++'  "${HF_NoHost}" > "${HF_NoHost_ND}"

    ## Type 1: absolutely path
    # Sort the header files with absolutely path. Contain the toolchain libc header files, linux kenrel header files
    grep '^\/' "${HF_NoHost}" > "${HF_AbPath}"
    awk '!seen[$0]++'  "${HF_AbPath}" > "${HF_AbsPath_ND}"
    ## Type 2: relative path
    # Sort the header files with relative path, only the linux kernel header files
    grep -v '^\/' "${HF_NoHost}" > "${HF_RelPath}"
    awk '!seen[$0]++'  "${HF_RelPath}" > "${HF_RelPath_ND}"

    ## Handle the Type 2: relative path
    File_Not_Exist=
    KERNEL_VALID_HEADER_FILES=
    KERNEL_VALID_HEADER_FILES=`cat "${HF_RelPath_ND}"`
    echo; yes '-' | head -n$(tput cols) | tr -d '\n'
    echo "Header file list in relative path mode"
    for files in `echo "${KERNEL_VALID_HEADER_FILES}" | sed -e 's/\ /\n/g'`; do
        DIR_OF_FILES=`dirname "${files}"`
        if [ ! -e "${DIR_TO_BE_COUNT}"/"${files}" ]; then
            File_Not_Exist+="${DIR_TO_BE_COUNT}"/"${files}" 
            File_Not_Exist+=" "
            continue
        fi
        echo "${files}" >> "${Valid_HF}"
        ((Index++))
        echo -e -n "\rHeader file[.h] Index:\t"
        echo -e -n "\t[${Echo_Cyan_Text}${Index}${Echo_Color_Reset}]"
    done

    if [ -n "${File_Not_Exist}" ]; then
        #echo "${Echo_Red_Text}Some files not found, please check:${Echo_Color_Reset}"
        echo "${File_Not_Exist}" | sed -e 's/\ /\n/g'  >> "${NotFound_TT}"
    fi
    ## Handle the Type 1: absolutely path
    File_Not_Exist=
    DIR_OF_FILES=
    KERNEL_VALID_HEADER_FILES=
    KERNEL_VALID_HEADER_FILES=`cat "${HF_AbsPath_ND}"`

    ## For some dir is symbol link
    cd "${DIR_TO_BE_COUNT}" && PATH_OF_CODE_DIR=`echo "${PWD}"` && cd - > /dev/null
    #echo PATH_OF_CODE_DIR is "${PATH_OF_CODE_DIR}"

    echo
    yes '-' | head -n$(tput cols) | tr -d '\n'
    echo "Header file list in absolutely path mode"
    for files in `echo "${KERNEL_VALID_HEADER_FILES}" | sed -e 's/\ /\n/g'`; do
        ## SubType 1: header files in kernel code
        if [ -n `echo "${files}" | grep "${PATH_OF_CODE_DIR}"` ]; then
            # files                                           -->   DIR_OF_FILES
            #/home/XXX/YYY/kernel-ZZZ/include/XXX.h --> /kernel-ZZZ/include/XXX.h
            DIR_OF_FILES=`echo "${files}" | sed -r "s#${PATH_OF_CODE_DIR}##"`

            #/kernel-ZZZ/include/XXX.h  -->   /kernel-ZZZ/include/
            DIR_OF_FILES=`dirname "${DIR_OF_FILES}"`

            #echo DIR_OF_FILES is "${DIR_OF_FILES}"
            if [ ! -e "${files}" ]; then
                File_Not_Exist+="${files}" 
                File_Not_Exist+=" "
                #echo "File not found: ${Echo_Red_Text}"${DIR_TO_BE_COUNT}"/"${files}" ${Echo_Color_Reset}"
                continue
            fi
            file_rel=`echo "${files}" | sed "s@^${REALPATH_DIR_TO_BE_COUNT}@@"`
            #echo "${file_rel}"
            echo "${file_rel}" >> "${Valid_HF}"
            ((Index++))
            echo -e -n "\rHeader file[.h] Index:\t"
            echo -e -n "\t[${Echo_Cyan_Text}${Index}${Echo_Color_Reset}]"
        ## Subtype 2: header file comes from the toolchain libc, we just skip it
        else
            continue
        fi
    done

    if [ -n "${File_Not_Exist}" ]; then
        echo "${Echo_Red_Text}Some files not found, please check:${Echo_Color_Reset}"
        echo "${File_Not_Exist}" | sed -e 's/\ /\n/g'  >> "${NotFound}"
    fi

    ## See whether the file is existed
    if [ -f "${NotFound_Verified}" ] ; then
        echo "Starting verify type2" >> "${NotFound_Verified}"
        for files in `cat "${NotFound_TT}"`; do
            filename=`echo "${files}" | sed 's/^.*\///'`
            #echo "${filename}"
            Exist=`grep "${filename}" "${Valid_HF}"`
            if [ -z "${Exist}" ] ; then
                echo "${files}" >> "${NotFound_Verified}"
            fi
        done
        echo "Done verify type2" >> "${NotFound_Verified}"
        echo "Done verify type2"
    fi
    ## See whether the file is existed
    if [ -f "${NotFound}" ] ; then
        for files in `cat "${NotFound}"`; do
            filename=`echo "${files}" | sed 's/^.*\///'`
            Exist=`grep "${filename}" "${Valid_HF}"`
            if [ -z "${Exist}" ] ; then
                echo "${files}" >> "${NotFound_Verified}"
            fi
        done
        echo "Done verify type1"
    fi

    if [ -e "${VALID_SRC}" -a -e "${Valid_HF}" ] ; then
        cat "${VALID_SRC}" "${Valid_HF}" > valid_filelist.txt
    fi
    sed "s@^@${REALPATH_DIR_TO_BE_COUNT}@" -i valid_filelist.txt

    echo
    for files in `cat valid_filelist.txt`; do
        if [ ! -e "${files}" ] ; then
            NotFoundFileName=`echo "${files}" | sed 's/^.*\///'`
            sed 's@${files}@@' -i valid_filelist.txt
            SearchMissFile=`find "${REALPATH_DIR_TO_BE_COUNT}" -name "${NotFoundFileName}"`
            if [ -n "${SearchMissFile}" ] ; then
                echo "${SearchMissFile}" >> valid_filelist.txt
            else
                ## exclude the libc header files
                if [ "stdarg.h" != "${NotFoundFileName}"  ] ; then
                    echo "Not found file: ${files}"
                fi
            fi
        fi
    done
fi

if [ "${SOURCE_CODE_TYPE}" = "UBOOT" ]; then
    PATH_OF_CODE_DIR=
    UBOOT_VALID_HEADER_FILES=
    UBOOT_SRC_WORK_DIR=uboot_src_work_dir
    UBOOT_HEADER_WORK_DIR=uboot_valid_header_files

    ## For some dir is symbol link
    cd "${DIR_TO_BE_COUNT}" && PATH_OF_CODE_DIR=`echo "${PWD}"` && cd - > /dev/null

    # the source file used to be compiled (.S .s .c), exclude the tools and examples directories
    UBOOT_VALID_SRC_FILES=
    UBOOT_VALID_SRC_FILES=`cd "${DIR_TO_BE_COUNT}" && find -name .depend ! -path "./tools/*"  ! -path "./examples/*" \
        | xargs  grep ':' | sed -e 's/.depend.*: //g' | sed -e 's/\ .*$//' && cd - >/dev/null`

    #######################################################################
    # .S .c .s source file
    #######################################################################
    # file not found in dir_to_be_count
    File_Not_Exist=
    Index=0
    for files in `echo "${UBOOT_VALID_SRC_FILES}" | sed -e 's/\ /\n/g'`; do
        DIR_OF_FILES=`dirname "${files}"`
        if [ ! -e "${DIR_TO_BE_COUNT}"/"${files}" ]; then
            File_Not_Exist+="${DIR_TO_BE_COUNT}"/"${files}" 
            File_Not_Exist+=" "
            continue
        fi
        echo "${files}" >> "${VALID_SRC}"
        ((Index++))
        echo -e -n "\rSource file[.c .S .s] Index: "
        echo -e -n "\t[${Echo_Cyan_Text}${Index}${Echo_Color_Reset}]"
    done
    echo

    ## the depend is seperate to 2 line in .depend.XXX, eg:
    #   a.o: \
    #   c.c
    # So we should remove the c.c
    Src_In_Next_Line=`find "${DIR_TO_BE_COUNT}" -name .depend | xargs egrep ':[[:space:]]+\\$' -A 1 -h | awk 'BEGIN{RS="--"  } {print $1 $3}' | sed 's/o:.*\.//' | sed 's/spl//'`

    for files in `echo "${Src_In_Next_Line}" | sed -e 's/\ /\n/g'`; do
        if [ ! -e "${files}" ] ; then
                echo "${files}" >> "${VALID_SRC}"
        else
                echo "Not found:${files}"
        fi
    done

    ## Handler the spl files, for these files the .c file path in .depend add a spl, lets remove it
    for files in `echo "${File_Not_Exist}" | sed -e 's/\ /\n/g'`; do
        if [ ! -e "${files}" ] ; then
            #echo ccc
            NotFound_Remove_SPL=`echo "${files}" | sed 's@spl@@'`
            if [ -e "${NotFound_Remove_SPL}" ] ; then
                echo "${NotFound_Remove_SPL}" >> "${VALID_SRC}"
                File_Not_Exist=`echo "${File_Not_Exist}" | sed "s@${files}@@"`
            fi
        fi
    done

    if [ -n "${File_Not_Exist}" ]; then
        echo
        echo "${Echo_Red_Text}Check file status${Echo_Color_Reset}"
        for files in `echo "${File_Not_Exist}" | sed -e 's/\ /\n/g'`; do
            ## for the line like these: /home/github/BBB/u-boot/./spl/arch/arm/cpu/armv7/\
            End_With_Slash=`echo "${files: -1}"`
            if [ -z "${End_With_Slash}" ] ; then
                echo "${files}"
                #echo "${File_Not_Exist}" | sed -e 's/\ /\n/g' #| tr -d '\n' #sed 's/^$//'
            fi
        done
    fi

    #######################################################################
    # .h header file copy
    #######################################################################
    # file not found in dir_to_be_count
    File_Not_Exist=
    Index=0

    # Find all the header files, include the host PCs, which is start with /usr
    find "${DIR_TO_BE_COUNT}" -name .depend ! -path "./tools/*"  ! -path "./examples/*" | xargs sed 's/^.*:\ .*\.[c|s|S]//' | tr -d '\\' | sed 's/\ /\n/g'\
        > "${HeadFileList_All}"
    # Remove the : line
    sed -i '/:/d' "${HeadFileList_All}"
    # Remove blank lines
    sed  '/^$/d' -i "${HeadFileList_All}"
    # Exclude the hostPCs header file. remain the toolchain libc header, linux uboot headerfiles
    grep -v '^\/usr' "${HeadFileList_All}" > "${HF_NoHost}"
    awk '!seen[$0]++' "${HF_NoHost}" > "${HF_NoHost_ND}"

    ## Type 1: absolutely path
    # Sort the header files with absolutely path. Contain the toolchain libc header files, linux kenrel header files
    grep '^\/' "${HF_NoHost}" > "${HF_AbPath}"
    awk '!seen[$0]++' "${HF_AbPath}" > "${HF_AbsPath_ND}"
    ## Type 2: no path file
    # Sort the header files with no path file, only the linux uboot header files
    grep -v '^\/' "${HF_NoHost}" > "${HF_NoPath}"
    awk '!seen[$0]++' "${HF_NoPath}" > "${HF_NoPath_ND}"

    ## Handle the Type 2: No path file
    File_Not_Exist=
    PATH_OF_NOPATH_FILE=
    UBOOT_VALID_HEADER_FILES=
    UBOOT_VALID_HEADER_FILES=`cat "${HF_NoPath_ND}"`
    for files in `echo "${UBOOT_VALID_HEADER_FILES}" | sed -e 's/\ /\n/g'`; do
        #echo files is ${files}
        cd "${DIR_TO_BE_COUNT}" && \
            PATH_OF_NOPATH_FILE=`find -name .depend.* | xargs grep -w ${files} -nIR | \
            sed "s@\.depend.*${files}@${files}@" | \
            tr -d '\\' 2>/dev/null` \
        && cd - > /dev/null

        #echo PATH_OF_NOPATH_FILE is $PATH_OF_NOPATH_FILE
        PATH_OF_NOPATH_FILE=`echo ${PATH_OF_NOPATH_FILE} | awk -F' ' '{print $1}'`
        #echo PATH_OF_NOPATH_FILE is $PATH_OF_NOPATH_FILE

        DIR_OF_FILES=`dirname "${PATH_OF_NOPATH_FILE}"`
        if [ ! -e ${DIR_TO_BE_COUNT}/${PATH_OF_NOPATH_FILE} ]; then
            File_Not_Exist+=${DIR_TO_BE_COUNT}/${PATH_OF_NOPATH_FILE} 
            File_Not_Exist+=" "
            #echo "${DIR_TO_BE_COUNT}/${PATH_OF_NOPATH_FILE} not found!"
            continue
        fi
        echo "${files}" >> "${Valid_HF}"
        ((Index++))
        echo -e -n "\rHeader file[.h] Index: "
        echo -e -n "[${Echo_Cyan_Text}${Index}${Echo_Color_Reset}]"
    done
    #echo -e "${Echo_Green_Text}...Done${Echo_Color_Reset}"
    #echo -e "\nType 2 item number: ${Index}"

    if [ -n "${File_Not_Exist}" ]; then
        #echo "${Echo_Red_Text}Some files not found, see file: "${NotFound_TT}"${Echo_Color_Reset}"
        echo "${File_Not_Exist}" | sed -e 's/\ /\n/g'  >> "${NotFound_TT}"
    fi

    ## Handle the Type 1: absolutely path
    File_Not_Exist=
    DIR_OF_FILES=
    UBOOT_VALID_HEADER_FILES=
    UBOOT_VALID_HEADER_FILES=`cat "${HF_AbsPath_ND}"`

    ## For some dir is symbol link
    cd "${DIR_TO_BE_COUNT}" && PATH_OF_CODE_DIR=`echo "${PWD}"` && cd - > /dev/null
    #echo PATH_OF_CODE_DIR is "${PATH_OF_CODE_DIR}"

    for files in `echo "${UBOOT_VALID_HEADER_FILES}" | sed -e 's/\ /\n/g'`; do
        ## SubType 1: header files in uboot code
        if [ -n `echo "${files}" | grep "${PATH_OF_CODE_DIR}"` ]; then
            # files                                           -->   DIR_OF_FILES
            #/home/XXX/YYY/uboot-ZZZ/include/XXX.h --> /uboot-ZZZ/include/XXX.h
            DIR_OF_FILES=`echo "${files}" | sed -r "s#${PATH_OF_CODE_DIR}##"`

            #/uboot-ZZZ/include/XXX.h  -->   /uboot-ZZZ/include/
            DIR_OF_FILES=`dirname "${DIR_OF_FILES}"`

            #echo DIR_OF_FILES is "${DIR_OF_FILES}"
            if [ ! -e "${files}" ]; then
                File_Not_Exist+="${files}" 
                File_Not_Exist+=" "
                #echo "File not found: ${Echo_Red_Text}"${DIR_TO_BE_COUNT}"/"${files}" ${Echo_Color_Reset}"
                continue
            fi

            file_rel=`echo "${files}" | sed "s@^${REALPATH_DIR_TO_BE_COUNT}@@"`
            echo "${file_rel}" >> "${Valid_HF}"
            ((Index++))
            echo -e -n "\rType 1 header file[.h], item index: "
            echo -e -n "[${Echo_Cyan_Text}${Index}${Echo_Color_Reset}]"
        ## Subtype 2: header file comes from the toolchain libc, we just skip it
        else
            continue
        fi
    done
    #echo -e "${Echo_Green_Text}.\tDone${Echo_Color_Reset}"

    if [ -n "${File_Not_Exist}" ]; then
        echo "${Echo_Red_Text}Some files not found, please check:${Echo_Color_Reset}"
        echo "${File_Not_Exist}" | sed -e 's/\ /\n/g'  > "${NotFound}"
    fi

fi
    ############################################################################
    ### Generate the filelist 
    ############################################################################
    sed "s@^${REALPATH_DIR_TO_BE_COUNT}@@" -i ${Valid_HF}
    sed "s@^${REALPATH_DIR_TO_BE_COUNT}@@" -i ${VALID_SRC}
    if [ -e "${VALID_SRC}" -a -e "${Valid_HF}" ] ; then
        cat "${VALID_SRC}" "${Valid_HF}" > valid_filelist.txt
    fi
    sed "s@^@${REALPATH_DIR_TO_BE_COUNT}@" -i valid_filelist.txt

    for files in `cat valid_filelist.txt`; do
        if [ ! -e "${files}" ] ; then
            NotFoundFileName=`echo "${files}" | sed 's/^.*\///'`
            sed 's@${files}@@' -i valid_filelist.txt
            SearchMissFile=`find "${REALPATH_DIR_TO_BE_COUNT}" -name "${NotFoundFileName}"`
            if [ -n "${SearchMissFile}" ] ; then
                echo "${SearchMissFile}" >> valid_filelist.txt
            else
                ## Remove the not found files
                #echo "Not found file: ${files}"
                sed "s@${files}@@" -i valid_filelist.txt
                sed '/^$/d' -i valid_filelist.txt
            fi
        fi
    done
    ## ./ --> /, // --> /
    sed "s@\./@/@" -i valid_filelist.txt
    sed "s@//@/@" -i valid_filelist.txt

    for files in `cat valid_filelist.txt`; do
        if [ ! -e "${files}" ] ; then
            sed "s@${files}@@" -i valid_filelist.txt
            sed '/^$/d' -i valid_filelist.txt
        fi
    done
    sed "s@^${REALPATH_DIR_TO_BE_COUNT}@@" valid_filelist.txt > valid_filelist_NoPath.txt
    cp valid_filelist_NoPath.txt FileList_SourceInsight.txt
    cp valid_filelist.txt FileList_understand.txt

    #sed "s@^@${REALPATH_DIR_TO_BE_COUNT}@" -i valid_filelist.txt
    cat "${Valid_HF}" | sed "s@^@${REALPATH_DIR_TO_BE_COUNT}@" | sed 's/^/<F N="/' | sed 's/$/"\/>/' | sed 's/^/\t\t\t/' > valid_hf_se.txt
    cat "${VALID_SRC}" | sed "s@^@${REALPATH_DIR_TO_BE_COUNT}@" | sed 's/^/<F N="/' | sed 's/$/"\/>/'| sed 's/^/\t\t\t/'  > valid_src_se.txt
    sed "s@\./@/@" -i valid_hf_se.txt
    sed "s@//@/@"  -i valid_hf_se.txt
    sed "s@\./@/@" -i valid_src_se.txt
    sed "s@//@/@"  -i valid_src_se.txt

    cp misc/sample.vpj .
    cp misc/sample.vpw .
    ## !!TODO!! Add the dts file
    ## Append to project file
    sed '/<!--SRCFILES-->/r valid_src_se.txt' -i sample.vpj
    sed '/<!--HEADFILES-->/r valid_hf_se.txt' -i sample.vpj
    sed "s/PRJNAME/${RESULT_PRJ}/" -i sample.vpj
    sed "s/PRJNAME/${RESULT_PRJ}/" -i sample.vpw
    mkdir "${RESULT_PRJ}"/"${RESULT_PRJ}" 
    mv sample.vpj "${RESULT_PRJ}"/"${RESULT_PRJ}"/"${RESULT_PRJ}".vpj
    mv sample.vpw "${RESULT_PRJ}"/"${RESULT_PRJ}"/"${RESULT_PRJ}".vpw
    mv valid*.txt "${Gen_Tmp}"
    mv FileList_understand.txt "${RESULT_PRJ}"
    mv FileList_SourceInsight.txt "${RESULT_PRJ}"
    rm ."${Gen_Tmp}" -rf 2>/dev/null && mv "${Gen_Tmp}" ."${Gen_Tmp}"
    sync

if [ "${SOURCE_CODE_TYPE}" = "UNKNOWN" ]; then
    echo UNKNOWN
fi

echo -e "${Echo_Yellow_BG}"
echo -e "${Echo_Color_Reset}"
yes '-' | head -n$(tput cols) | tr -d '\n'

exit 0
