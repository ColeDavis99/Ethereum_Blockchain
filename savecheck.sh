#!/bin/bash

#Version 0.1

: ' This script will be ran every time the audit library detects a change. This script selectively takes some of the output of these commands:

        Phase 1 of script:   ausearch -k watch_key | aureport -f -i | tail -1
        Phase 2 of script:   ausearch -k watch_key | tac | sed "/----/q"

and creates a more human-readable version. The information is then stored in a final array formatted like this:

          [filename, modification type, time, linuxUserID, fileDirectory, GitRepoHash]

Then all the information gets output to a text file
'

#======================
# Utility Functions
#======================
sanitizeEvent () {

  #Ignore .swp files
  fileName=${EventDetails[4]}
  if [[ ${fileName: -4} = ".swp" ]]
  then
    echo "Ignore this swp file"
    exit 1
  fi

  #Ignore .git stuff
  if [[ ${EventDetails[7]} = "/usr/bin/git" ]]
  then
    echo "SANITIZEDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD"
    exit 1
  fi
}

#======================
# Functions for phase 2
#======================

#Detect when the user deleted a file from a GUI
guiDelete () {
  trashDirectoryAccessed=`echo ${EventDetails[4]} | grep /Trash/files/`

  if [[ ${EventDetails[7]} = "/usr/bin/nautilus" && $trashDirectoryAccessed != "" ]]
  then
      grepResults[4]="deletedFromGui"

      #Used for determining what directory this file/dir got deleted from (Digging through the trash directory)
      trashName=$(basename ${EventDetails[4]})

      trashInfo=$(cat ~/.local/share/Trash/info/$trashName.trashinfo | head -2 | tail -1)

      FinalInfo[5]=$(echo "${trashInfo:5}")
      FinalInfo[1]=$(basename ${trashInfo})
  fi
}

#Detect when the user modified a file via GUI
guiModify () {
  outputStreamAccessed=`echo ${EventDetails[4]} | grep /.goutputstream`

  if [[ ${EventDetails[7]} = "/usr/bin/gedit" && ${EventDetails[5]} = "rename" ]]
  then
      grepResults[5]="modifiedFromGui"
  fi
}

#Get the Linux user's ID  (FinalInfo[4] = LinuxUserID)
parseUserID () {
  #Grep lastEventP2 with "uid=" and return everthing after until a space is encountered.
  linuxUserID=$(echo $lastEventP2 | grep -oP '(?<= uid=)(\s+)?\K([^ ]*)')
  FinalInfo[4]=$linuxUserID
}




#======================
#    MAIN DRIVER
#======================
#DECLARE CONSTANTS
WATCHEDDIR="/home/cole/Desktop/BLOCKCHAIN/watch_dir"
BASEDIR=$(basename $WATCHEDDIR)
DEBUGMODE=0  #1 prints extra info to example.txt, 0 is normal operation mode



#===========================#
#         PHASE 1
#===========================#

#Get the event passed in via command line
lastEventP1=$1
echo
echo "YAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA:"
echo $lastEventP1
#echo $lastEventP1 >> /home/cole/Desktop/please.txt




#Declare associative array that holds details about most recent user event
#LineNo date      time   file  syscall  success  exe  auid  event
#4803. 01/13/2020 10:03:04 . openat yes /usr/bin/ls cole 3541
declare -A EventDetails
EventDetails=([1]=NULL [2]=NULL [3]=NULL [4]=NULL [5]=NULL [6]=NULL [7]=NULL [8]=NULL [9]=NULL)


#Populate temp array with values from phase 1 command
ctr=1
for info in $lastEventP1
do
	EventDetails[$ctr]=$info
	((ctr+=1))
	echo "$info"
done


#Abort the script if we're working with an .swp file, or some internal .git stuff
sanitizeEvent
echo $lastEventP1 >> /home/cole/Desktop/please.txt



#FinalInfo will hold the final values we put in the blockchain:                 [filename, modificationType, time, linuxUserId, FileDirectory, GitRepoHash]
declare -A FinalInfo
FinalInfo=([1]=NULL [2]=NotSureWhatCommandThatWas [3]=NULL [4]=NULL [5]=NULL [6]=NULL)

#"first half" of the script ( Assigning [3]filename, [4]time, [8]userID from old array to the new, final array.)
FinalInfo[1]=$(basename ${EventDetails[4]}) #filename
FinalInfo[3]=${EventDetails[3]} #time
# FinalInfo[4]=${EventDetails[8]} #userName






#===============================#
#         PHASE 2
#===============================#
#Do the second phase's command
lastEventP2=$2

echo "THIS IS PHASE 2"
echo $lastEventP2
#echo $lastEventP2 >> /home/cole/Desktop/please.txt



#Store the result of grep (and other) commands to determine modification type (touch, mkdir, remove, )
declare -A grepResults
grepResults=([1]=NULL [2]=NULL [3]=NULL [4]=NULL [5]=NULL [6]=NULL)


# Hard-codey demo tests used to determine modification type
grepResults[1]=`echo "$lastEventP2" | grep comm=\"touch\"`
grepResults[2]=${EventDetails[5]}
grepResults[3]=`echo "$lastEventP2" | grep comm=\"rm\"`
guiDelete #grepResults[4]=guiDelete
guiModify #grepResults[5]=guiModify
parseUserID #FinalInfo[4] = LinuxUserID



#Determine what the nature of the users actions were based on the 5 hard-codey tests  [(x), (X), (x), (x), (), ()]. Also determine the directory.
if [[ ${grepResults[1]} != "" ]]
then
  FinalInfo[2]="File Creation CLI"
  fileCreationPath=$(echo $lastEventP2 | grep -Po 'item=0 name=".*?"')
  fileCreationPath=$(echo $fileCreationPath | cut -c 14-)
  FinalInfo[5]=${fileCreationPath:: -1}

elif [[ ${grepResults[2]} = "mkdir" ]]
then
  FinalInfo[2]="Directory Creation"

  fileCreationPath=$(echo $lastEventP2 | grep -Po 'item=0 name=".*?"')
  fileCreationPath=$(echo $fileCreationPath | cut -c 14-)
  FinalInfo[5]=${fileCreationPath:: -1}

elif [[ ${grepResults[3]} != "" ]]
then
  FinalInfo[2]="File or Directory Deletion CLI"
  trashName=$(basename ${EventDetails[4]})

  fileCreationPath=$(echo $lastEventP2 | grep -Po 'item=0 name=".*?"')
  fileCreationPath=$(echo $fileCreationPath | cut -c 14-)
  FinalInfo[5]=${fileCreationPath:: -1}

  #Solution 1 (Broke because rm command doesn't move things to the trash)
  # trashInfo=$(cat ~/.local/share/Trash/info/$trashName.trashinfo | head -2 | tail -1)
  # FinalInfo[5]=$(echo "${trashInfo:5}")
  # FinalInfo[1]=$(basename ${trashInfo})

elif [[ ${grepResults[4]} = "deletedFromGui" ]]
then
  FinalInfo[2]="File or Directory Deleted via GUI"

elif [[ ${grepResults[5]} = "modifiedFromGui" ]]
then
  FinalInfo[2]="File modified from GUI"
  FinalInfo[5]=${EventDetails[4]}

else
  exit 1 # There was some event that happened that the 5 tests above did not trigger (rename, unlink, etc...)
fi







CURRENTEPOCTIME=`date +%s%N`
#touch /home/cole/Desktop/dates/"${CURRENTEPOCTIME}"

FinalInfo[3]=$CURRENTEPOCTIME



#Retrieve the hash and re-commit so there's a new hash for when the next event happens
cd $WATCHEDDIR
git add *
git commit -m "commit_message"
FinalInfo[6]=$(git rev-parse HEAD)


if [[ $DEBUGMODE = 1 ]]
then
  echo "Did git stuff." >> /home/cole/Desktop/BLOCKCHAIN/testserver/example.txt
fi


echo
echo ${FinalInfo[1]} #file name
echo ${FinalInfo[2]} # type of modification
echo ${FinalInfo[3]} # unix time
echo ${FinalInfo[4]} # linux user ID
echo ${FinalInfo[5]} # directory event took place
echo ${FinalInfo[6]} # hash


# 1 = in debug mode
if [[ $DEBUGMODE = 1 ]]
then
  echo ${FinalInfo[1]}@@@${FinalInfo[2]}@@@${FinalInfo[3]}@@@${FinalInfo[4]}@@@${FinalInfo[5]}@@@${FinalInfo[6]} >> /home/cole/Desktop/BLOCKCHAIN/testserver/example.txt
  echo  >> /home/cole/Desktop/BLOCKCHAIN/testserver/example.txt
else
  echo ${FinalInfo[1]}@@@${FinalInfo[2]}@@@${FinalInfo[3]}@@@${FinalInfo[4]}@@@${FinalInfo[5]}@@@${FinalInfo[6]} > /home/cole/Desktop/BLOCKCHAIN/testserver/events/example.txt
  echo ${FinalInfo[1]}@@@${FinalInfo[2]}@@@${FinalInfo[3]}@@@${FinalInfo[4]}@@@${FinalInfo[5]}@@@${FinalInfo[6]} > /home/cole/Desktop/BLOCKCHAIN/testserver/events/$CURRENTEPOCTIME

fi
