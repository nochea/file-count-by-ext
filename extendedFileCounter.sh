#!/usr/bin/env bash

# script is linked (ln) to /usr/bin/extendedfilecounter

# Tell bash to exit if it encounters a failure (Non zero exit status code)
set -e

# Set secure $PATH
PATH='/usr/local/bin:/bin:/usr/bin'
export PATH

function usage ()
{
  printf "Usage: %s: [-a] [-d working directory] [-e file type] [-h] [-i] [-l]\n" $(basename $0) >&2
  exit 0
}

function isDir ()
{
  if [ ! -d "$dval" ] 
  then
    printf "%b" "Error: $dval should be a directory\n" >&2
    printf "Usage: %s: [-a] [-d working directory] [-e file type] [-h] [-i] [-l]\n" $(basename $0) >&2
    exit 1
  fi
}

function calculator ()
{
    TOTAL_KB=$(echo "scale=4; $TOTAL/1024" | bc -l)
    TOTAL_MB=$(echo "scale=4; ($TOTAL/1024)/1024" | bc -l)
    TOTAL_GB=$(echo "scale=4; (($TOTAL/1024)/1024)/1024" | bc -l)

    printf "total file size for $dval directory: Bytes: $TOTAL\n" >&2
    printf "total file size for $dval directory: KBytes: $TOTAL_KB\n" >&2 
    printf "total file size for $dval directory: MBytes: $TOTAL_MB\n" >&2
    printf "total file size for $dval directory: GBytes: $TOTAL_GB\n" >&2
}

# Test if enough args are specified
if (($# == 0))
then
  printf "%b" "Error: No argument specified.\n" >&2
  usage
fi




# Using getopts bash built-in to parse command-line arguments and options
#
# -a : global size of working directory takin in account every file extension
# -d : working directory
# -e : file extension searched
# -i : interactive mode
# -l : listing 
# -h : help show usage

aflag=
dflag=
eflag=
hflag=
iflag=
lflag=

# colons(:) is used to indicate which option needs an argument
while getopts ':ad:e:hil' OPTION
do
  case $OPTION in
  a)  aflag=1
      ;;
  d)  dflag=1
      dval="$OPTARG"
      ;;
  e)  eflag=1
      eval="$OPTARG"
      ;;
  h)  hflag=1
      ;;
  i)  iflag=1
      ;;
  l)  lflag=1
      ;;
  \:) printf "Argument missing from -%s\n" $OPTARG
      usage
      ;;
  \?) usage
      ;;
  esac >&2
done

shift $(($OPTIND - 1))

# -a switch specified. Check if -d switch is also specified
if [ "$aflag" ]
then 
  if [ "$dflag" ]
  then 
    isDir
    TOTAL=`du -sb $dval | cut -f 1`
    calculator
    exit 0
  # else use current directory to perform the search
  elif [ -z "$dflag" ]
  then
    TOTAL=`du -sb . | cut -f 1`
    calculator
    exit 0
  fi
fi

# -d switch is specified. Check if directory exists
if [ "$dflag" ]
then
  isDir
  # directory exists. Check if -e flag is specified
  if [ "$eflag" ]
  then
    # -e flag specified. Check arg
    if [ "$eval" != "all" ]
    then
      # Display how many files are concerned
      NUMFOUND=`find ${dval} -name '*.'${eval} | wc -l`
      
      if (($NUMFOUND != 0))
      then
        echo "Found $NUMFOUND files with \"$eval\" extension"
      else
        echo "Found no files with $eval extension"
        exit 0
      fi

      # Declare an array. For each file found, put its size in tha array
      MFBT=$(find ${dval} -name '*.'${eval} -exec stat '{}' \; | grep Size: | cut -f 1  | tr -d '  Size:')
      declare -a MYARRAY
      MYARRAY=($MFBT)

      # Loop inside MYARRAY for each value and get total sum
      for (( i=0; i < $NUMFOUND; i++ ))
      do
        let TOTAL+=${MYARRAY[i]}
      done
      calculator
    elif [ "$eval" = "all" ]
    then
      TOTAL=`du -sb $dval | cut -f 1`
      calculator
    fi
  elif [ -z "$eflag" ]
  # Same case as -a -d do a weight calculation for all file within specified directory
  then
    TOTAL=`du -sb $dval | cut -f 1`
    calculator
  fi
fi

# -e switch specified


# -h switch specified. Show usage
if [ "$hflag" ]
then
  usage
fi


# -i switch specified. Interactive mode selected. Check to see if only this option is passed.
if [ "$iflag" ]
then
  printf 'Interactive mode selected, welcome !\n'
  if [ "$dflag" ]
  then
    printf 'Interactive mode not compatible with -d or -e\n'
    usage
  fi
  if [ "$eflag" ]
  then
    printf 'Interactive mode not compatible with -d or -e\n'
    usage
  fi
  # following are known music file type extension, displayed nicely
  MYEXTENSION=(aiff flac ogg ogv m4a mp3 mp4 wav wma)
  declare -a MYEXTENSION
  for (( i=0; i < ${#MYEXTENSION[@]}; i++ ))
    do
      printf '%4.4s : %s\n' ${MYEXTENSION[i]} [$i]
    done
  exit 0
fi


# -l Option specified. Listing asked.
if [ "$lflag" ]
then
  current_location=`pwd`
  `tree ${dval} -L 4 -H $current_location/${dval} -CDF -supa --inodes -o index.html`
  printf "index.html created here"
  exit 0
fi
