#!/bin/bash

########################
# INIT VARIABLES
#########################
previousEventNumber=$(ausearch -k watch_key | aureport -f -i | tail -1 | sed 's/.* //')
recentEventNumber=$(ausearch -k watch_key | aureport -f -i | tail -1 | sed 's/.* //')
batchEventPhase1=""
batchEventPhase2=""

batchArr=()

eventID=0


#Generates an event file for every event that occurs between $previousEventNumber and $recentEventNumber
#This makes sure if a parent directory is deleted, every subfile/dir gets detected too.



while true
do
  #Keep track of the most recently recorded event no.
  recentEventNumber=$(ausearch -k watch_key | aureport -f -i | tail -1 | sed 's/.* //')

  if [[ $recentEventNumber != $previousEventNumber ]]
  then

    echo "Recent event number: "
    echo $recentEventNumber

    echo "Previous event number: "
    echo $previousEventNumber

    #Detect how many events happened between the last run of this script
    numEventsToGenerate="$((recentEventNumber - previousEventNumber))"

    #Store a string containing all events that happened between the last run of this script
    batchEventPhase1=$(ausearch -k watch_key | aureport -f -i | tail -"$numEventsToGenerate")

    echo
    echo
    echo
    echo "Here's batchEvent, it's what we're going to be feeding into savecheck.sh: "
    echo "$batchEventPhase1"
    echo
    echo "Here's the number of events that happened "
    echo $numEventsToGenerate


    #Populate batchArr array with all of the events that have happened
    IFS=$'\n'
    while IFS= read -r eventPhase1; do
      batchArr+=($eventPhase1)
    done <<< "$batchEventPhase1"

    #Generate phase 2 command, and then run each event through ./savecheck.sh
    for eventPhase1 in "${batchArr[@]}"
    do
      eventID=$(echo $eventPhase1 | sed 's/.* //')
      #echo "THIS IS EVENTID: $eventID"

      eventPhase2=$(ausearch -a $eventID)
      #eventPhase2=$(ausearch -a $eventID)
      #echo "THIS IS eventPhase2:"
      #echo $eventPhase2

      #echo "BEFORE SAVECHECK"
      ./savecheck.sh "$eventPhase1" "$eventPhase2"
      #echo "AFTER SAVECHECK"
    done



    # echo "$batchEventPhase1" | while IFS= read -r eventPhase1
    # do
      # echo $eventPhase1
      # eventID=$(echo $eventPhase1 | sed 's/.* //')
      # echo "THIS IS EVENTID: $eventID"
      #
      # #eventID is not being registered properly and Im' getting <no matches> returned for some reason
      # #I can do this command outside of the while loop scope succesully though
      # eventPhase2=$(ausearch -a $eventID)
      # #eventPhase2=$(ausearch -a $eventID)
      # echo "THIS IS eventPhase2: $eventPhase2"
      #
      # echo "BEFORE SAVECHECK"
      # ./savecheck.sh "$eventPhase1" "$eventPhase2"
      # echo "AFTER SAVECHECK"
    # done

    #Now update the previous event number so future events are detected (and no duplicates)
    previousEventNumber=$recentEventNumber
    unset batchArr
  fi

done
