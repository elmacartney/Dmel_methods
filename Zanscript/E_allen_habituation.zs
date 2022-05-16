# DISCLAIMER:
# This sample script illustrates how zanscript can be written
# to run an experiment and deliver some example data.  Zantiks Ltd cannot guarantee 
# this is how you want to run your experiments, this script is offered
# only to demonstrate the capabilities of the system and assist you in learning how 
# to script for your research.

# The script below is for studying animal movement in the Zantiks Ltd MWP unit.
# This script can be adapted for circadian rhythm, startle, habituation and PPI experiments.

# To run this script you need the appropriate well bitmap in your assets directory. You can
# check which bitmap is needed at the bottom of this script, depending on how many wells
# you are using.

# If the opto-genetic light is being used, it must be connected to relay 2, in slot CN3.

##########################################

INCLUDE zsys

#Vibration or light off experiment
DEFINE VIBRATE 0								# 0 = light off, 1 = vibration
DEFINE TIMESLOT 1
DEFINE SPONTANEOUS_RECOVERY	1					# 0 = habituation, 1 = habituation plus spontaneous recovery test

#Adjust to change number of repeats and timing
DEFINE TEMPERATURE 22
DEFINE NUM_WELLS 48								# 6, 12, 24, 48, 96 well-plate
DEFINE DELAY_START_SECS 0                       # delays the start of the experiment
DEFINE ACCLIMATION_TIME 3						# initial acclimation period for animals to adjust to environment - units is the length of SAMPLE_TIME_SECS
DEFINE NUM_REPS_OF_SEQUENCE 2					# repeats of the procedure
DEFINE SAMPLE_TIME_SECS 1						# time over which movement is sampled (set to 1 for circadian rhythm)

#Startle settings
DEFINE NUM_PRE 3								# number of still trials before startles in a block
DEFINE NUM_POST 3								# number of still trials after startles in a block
DEFINE CONSECUTIVE_STARTLES 3					# number of startles in a row for habituation (for single startle = 1)
DEFINE TIME_BETWEEN_STARTLE_TRIALS 1			# must be integer, can be 0
DEFINE OPTO_BRIGHTNESS 0                        # optolight brightness (0 = max, 10000 = off)
DEFINE VIDEO_LENGTH 8

#Spontaneous recovery settings
DEFINE RECOVERY_TIME_SECS 10					# time before startle recovery test and/or fatigue test (-1 from desired value)
DEFINE TIME_BEFORE_NEXT_BLOCK 10				# time after recovery test before habituation begins again

#These SET commands are necessary for tracking, these are appropriate for adult drosophila
IF VIBRATE = 0
    SET(TILE_SIZE,5)
    SET(DETECTOR_THRESHOLD,10)
    SET(SEARCH_DISTANCE,9)
    SET(SEARCH_STEP,3)
    SET(FILTER_RADIUS,8)
ENDIF

IF VIBRATE = 1
	SET(TILE_SIZE,5)
	SET(DETECTOR_THRESHOLD,8)
	SET(SEARCH_DISTANCE,9)
	SET(SEARCH_STEP,3)
	SET(FILTER_RADIUS,8)
ENDIF

SET(AUTOREF_MODE,1)
SET(AUTOREF_TIMEOUT,30)						# sets the max time for detection of animals when initiating tracking

#DEFINE X_LOGDATA_TRACKS 799					# Development setting: log track lengths (total) 
DEFINE X_DRAWTRACKS 30011           			# Development setting: enable track drawing
    
#Temperature control settings
SET(TCS_MODE,PELTIER)
SET(THERMOSTAT,TEMPERATURE)

#MSD settings
SET(MSD_MODE,ON)
SET(MSD_THRESHOLD,15)

#Define light for stimulus interval on video
SETLIGHT(LIGHT1,2,100,50,100)


##########################################

ACTION MAIN
    
# Turns overhead light and screen off at the start of experiment
    INVOKE(DARK)
    
# Sets the data output counter label to begin at 0. The counter is used in the script below to label the data in numerical order.
	SET(COUNTER1,COUNTER_ZERO)					# time bin
    # Startle experiment counters
    SET(COUNTER2,COUNTER_ZERO)					# block counter - increments at the start of each block, resets upon repeat of sequence
    SET(COUNTER3,COUNTER_ZERO)					# trial counter - resets at the start of each block, used for habituation experiments
    SET(COUNTER4,COUNTER_ZERO)					# pre and post counter
    
    SET(COUNTER5,COUNTER_ZERO)					# counter to write in timeslot
    INVOKE(TIMESLOT_INC,TIMESLOT)
    
    SET(COUNTER6,COUNTER_ZERO)					# startle in sequence counter

# Creates headers for columns in the data file
	LOGCREATE("TEXT:RUNTIME|TEXT:UNIT|TEXT:TIMESLOT|TEXT:PLATE_ID|TEXT:TEMPERATURE")
	LOGAPPEND("TEXT:TIME_BIN|TEXT:BLOCK|TEXT:TRIAL|TEXT:TYPE|TEXT:PRE_POST_COUNTER")				# change type headings as appropriate, e.g. startle type or light/dark, change to blank if not needed
	LOGAPPEND("TEXT:STARTLE_NUMBER")

    IF NUM_WELLS = 6							# completes correct headers and loads arenas
    	INVOKE(WELL_6)
    ENDIF
    
    IF NUM_WELLS = 12
    	INVOKE(WELL_12)
    ENDIF
   
    IF NUM_WELLS = 24
    	INVOKE(WELL_24)
    ENDIF
    
    IF NUM_WELLS = 48
    	INVOKE(WELL_48)
    ENDIF
    
    IF NUM_WELLS = 96
    	INVOKE(WELL_96)
    ENDIF
    
    LOGRUN()

# Delays start of experiment and then runs acclimation protocol
    WAIT(DELAY_START_SECS)
    INVOKE(ACCLIMATION_LIGHT)
    
#Runs procedure over a set number of repeats
	INVOKE(SEQUENCE,NUM_REPS_OF_SEQUENCE)
    	
COMPLETE


ACTION TIMESLOT_INC

	SET(COUNTER5,COUNTER_INC)
    
COMPLETE


ACTION ACCLIMATION_LIGHT

	IF VIBRATE = 1
    	INVOKE(LT_WHITE)
    ENDIF
    
    IF VIBRATE = 0
		INVOKE(OPTO_ON)
    ENDIF
    
    AUTOREFERENCE()									# Creates a reference image for tracking - needed after every hour
	SET(X_DRAWTRACKS,1)
    
    INVOKE(ACCLIMATION_SAMPLE,ACCLIMATION_TIME)
    
COMPLETE


ACTION ACCLIMATION_SAMPLE

	SET(COUNTER1,COUNTER_INC)							# INC_rements the time_bin counter
    SET(COUNTER3,COUNTER_INC)							# INC_rements the trial counter

	LOGDATA(DATA_SNAPSHOT,"begin")                      # DATA_SNAPSHOT records info at the specific time indicated. Here the data at the beginning of the trial is recorded for later comparison with the next SNAPSHOT. You can change the name by editing inside the "".
 
 	WAIT(SAMPLE_TIME_SECS)

	LOGDATA(DATA_SNAPSHOT,"end")                        # Recording info at the end of trial. Here the data recorded is compared to the previous SNAPSHOT to give your data during the this previous time slot.
	LOGDATA(DATA_SELECT,"begin")                        # Data select command pulls the data from the named SNAPSHOT begin above.
	LOGDATA(DATA_DELTA,"end")                           # Data delta command does the calculation between the first SNAPSHOT in the series to the next one. In this SNAPSHOT "begin" is substracted from the SNAPSHOT "end" to give data variables.

 	LOGCREATE("RUNTIME|APPARATUS_ID|COUNTER5|SUBJECT_ID|TEMPERATURE1")
	LOGAPPEND("COUNTER1|COUNTER2|COUNTER3|TEXT:ACCLIMATION|TEXT:0|TEXT:0")
    LOGAPPEND("ARENA_DISTANCES:*|ARENA_ACTIVITY:*")                                          
	LOGRUN()
    
COMPLETE


ACTION SEQUENCE   

	SET(COUNTER2,COUNTER_INC)							# INC_rements the block counter
    SET(COUNTER3,COUNTER_ZERO)							# resets the trial counter
    
    SET(COUNTER4,COUNTER_ZERO)							# resets the pre and post counter
    INVOKE(PRESTARTLE,NUM_PRE)
    
    IF VIBRATE = 1
    	VIDEO(VIDEO_LENGTH,"mosq_habituation")
    ENDIF
    
    IF VIBRATE = 0
    	VIDEO(VIDEO_LENGTH,"dros_habituation")
	ENDIF
    
    INVOKE(PRESTARTLE,3)
    SET(COUNTER6,COUNTER_ZERO)							# resets the startle counter
    INVOKE(STARTLE,CONSECUTIVE_STARTLES)
    SET(COUNTER4,COUNTER_ZERO)							# resets the pre and post counter
    INVOKE(POSTSTARTLE,NUM_POST)
    
    IF SPONTANEOUS_RECOVERY = 1
    	SET(COUNTER4,COUNTER_ZERO)						# resets the pre and post counter, used for counting rests
    	INVOKE(REST,RECOVERY_TIME_SECS)
        
        IF VIBRATE = 1
    		VIDEO(VIDEO_LENGTH,"mosq_recovery")
    	ENDIF
    
    	IF VIBRATE = 0
    		VIDEO(VIDEO_LENGTH,"dros_recovery")
		ENDIF
    
    	INVOKE(REST,3)
    	INVOKE(RECOVERY_TEST)
        INVOKE(REST,TIME_BEFORE_NEXT_BLOCK)
    ENDIF
    
COMPLETE


########################################

ACTION PRESTARTLE
    
    SET(COUNTER1,COUNTER_INC)							# INC_rements the time_bin counter
    SET(COUNTER3,COUNTER_INC)							# INC_rements the trial counter
    SET(COUNTER4,COUNTER_INC)							# INC_rements the pre and post counter

	LOGDATA(DATA_SNAPSHOT,"begin")                      # DATA_SNAPSHOT records info at the specific time indicated. Here the data at the beginning of the trial is recorded for later comparison with the next SNAPSHOT. You can change the name by editing inside the "".
 
 	WAIT(SAMPLE_TIME_SECS)

	LOGDATA(DATA_SNAPSHOT,"end")                        # Recording info at the end of trial. Here the data recorded is compared to the previous SNAPSHOT to give your data during the this previous time slot.
	LOGDATA(DATA_SELECT,"begin")                        # Data select command pulls the data from the named SNAPSHOT begin above.
	LOGDATA(DATA_DELTA,"end")                           # Data delta command does the calculation between the first SNAPSHOT in the series to the next one. In this SNAPSHOT "begin" is substracted from the SNAPSHOT "end" to give data variables.

 	LOGCREATE("RUNTIME|APPARATUS_ID|COUNTER5|SUBJECT_ID|TEMPERATURE1")
    LOGAPPEND("COUNTER1|COUNTER2|COUNTER3|TEXT:PRE|COUNTER4|TEXT:0")
    LOGAPPEND("ARENA_DISTANCES:*|ARENA_ACTIVITY:*")                                          
	LOGRUN()

COMPLETE


ACTION POSTSTARTLE
    
    SET(COUNTER1,COUNTER_INC)							# INC_rements the time_bin counter
    SET(COUNTER3,COUNTER_INC)							# INC_rements the trial counter
    SET(COUNTER4,COUNTER_INC)							# INC_rements the pre and post counter

	LOGDATA(DATA_SNAPSHOT,"begin")                      # DATA_SNAPSHOT records info at the specific time indicated. Here the data at the beginning of the trial is recorded for later comparison with the next SNAPSHOT. You can change the name by editing inside the "".
 
 	WAIT(SAMPLE_TIME_SECS)

	LOGDATA(DATA_SNAPSHOT,"end")                        # Recording info at the end of trial. Here the data recorded is compared to the previous SNAPSHOT to give your data during the this previous time slot.
	LOGDATA(DATA_SELECT,"begin")                        # Data select command pulls the data from the named SNAPSHOT begin above.
	LOGDATA(DATA_DELTA,"end")                           # Data delta command does the calculation between the first SNAPSHOT in the series to the next one. In this SNAPSHOT "begin" is substracted from the SNAPSHOT "end" to give data variables.

 	LOGCREATE("RUNTIME|APPARATUS_ID|COUNTER5|SUBJECT_ID|TEMPERATURE1")
	LOGAPPEND("COUNTER1|COUNTER2|COUNTER3|TEXT:POST|COUNTER4|TEXT:0")
    LOGAPPEND("ARENA_DISTANCES:*|ARENA_ACTIVITY:*")                                          
	LOGRUN()

COMPLETE


ACTION STARTLE

    SET(COUNTER1,COUNTER_INC)							# INC_rements the time_bin counter
    SET(COUNTER3,COUNTER_INC)							# INC_rements the trial counter
    SET(COUNTER6,COUNTER_INC)							# INC_rements the startle counter

	LOGDATA(DATA_SNAPSHOT,"begin")                      # DATA_SNAPSHOT records info at the specific time indicated. Here the data at the beginning of the trial is recorded for later comparison with the next SNAPSHOT. You can change the name by editing inside the "".
	
    LIGHTS(LIGHT1,RED)
    
	IF VIBRATE = 1
    	INVOKE(VIBRATION)
    ENDIF
    
    IF VIBRATE = 0
		INVOKE(OPTO_FLASH)
    ENDIF
    
	WAIT(SAMPLE_TIME_SECS)
    
    LIGHTS(LIGHT1,OFF)    

	LOGDATA(DATA_SNAPSHOT,"end")                        # Recording info at the end of trial. Here the data recorded is compared to the previous SNAPSHOT to give your data during the this previous time slot.
	LOGDATA(DATA_SELECT,"begin")                        # Data select command pulls the data from the named SNAPSHOT begin above.
	LOGDATA(DATA_DELTA,"end")                           # Data delta command does the calculation between the first SNAPSHOT in the series to the next one. In this SNAPSHOT "begin" is substracted from the SNAPSHOT "end" to give data variables.

 	LOGCREATE("RUNTIME|APPARATUS_ID|COUNTER5|SUBJECT_ID|TEMPERATURE1")
	LOGAPPEND("COUNTER1|COUNTER2|COUNTER3|TEXT:STARTLE|TEXT:0|COUNTER6")
    LOGAPPEND("ARENA_DISTANCES:*|ARENA_ACTIVITY:*")                                          
	LOGRUN()
    
    INVOKE(BETWEEN_STARTLES,TIME_BETWEEN_STARTLE_TRIALS)
    
COMPLETE


ACTION BETWEEN_STARTLES

	SET(COUNTER1,COUNTER_INC)							# INC_rements the time_bin counter
    SET(COUNTER3,COUNTER_INC)							# INC_rements the trial counter

	LOGDATA(DATA_SNAPSHOT,"begin")                      # DATA_SNAPSHOT records info at the specific time indicated. Here the data at the beginning of the trial is recorded for later comparison with the next SNAPSHOT. You can change the name by editing inside the "".
 
 	WAIT(1)

	LOGDATA(DATA_SNAPSHOT,"end")                        # Recording info at the end of trial. Here the data recorded is compared to the previous SNAPSHOT to give your data during the this previous time slot.
	LOGDATA(DATA_SELECT,"begin")                        # Data select command pulls the data from the named SNAPSHOT begin above.
	LOGDATA(DATA_DELTA,"end")                           # Data delta command does the calculation between the first SNAPSHOT in the series to the next one. In this SNAPSHOT "begin" is substracted from the SNAPSHOT "end" to give data variables.

 	LOGCREATE("RUNTIME|APPARATUS_ID|COUNTER5|SUBJECT_ID|TEMPERATURE1")
	LOGAPPEND("COUNTER1|COUNTER2|COUNTER3|TEXT:BETWEEN|TEXT:0|COUNTER6")
    LOGAPPEND("ARENA_DISTANCES:*|ARENA_ACTIVITY:*")                                          
	LOGRUN()

COMPLETE


ACTION REST
    
    SET(COUNTER1,COUNTER_INC)							# INC_rements the time_bin counter
    SET(COUNTER3,COUNTER_INC)							# INC_rements the trial counter
    SET(COUNTER4,COUNTER_INC)							# INC_rements the pre and post counter

	LOGDATA(DATA_SNAPSHOT,"begin")                      # DATA_SNAPSHOT records info at the specific time indicated. Here the data at the beginning of the trial is recorded for later comparison with the next SNAPSHOT. You can change the name by editing inside the "".
 
 	WAIT(SAMPLE_TIME_SECS)

	LOGDATA(DATA_SNAPSHOT,"end")                        # Recording info at the end of trial. Here the data recorded is compared to the previous SNAPSHOT to give your data during the this previous time slot.
	LOGDATA(DATA_SELECT,"begin")                        # Data select command pulls the data from the named SNAPSHOT begin above.
	LOGDATA(DATA_DELTA,"end")                           # Data delta command does the calculation between the first SNAPSHOT in the series to the next one. In this SNAPSHOT "begin" is substracted from the SNAPSHOT "end" to give data variables.

 	LOGCREATE("RUNTIME|APPARATUS_ID|COUNTER5|SUBJECT_ID|TEMPERATURE1")
    LOGAPPEND("COUNTER1|COUNTER2|COUNTER3|TEXT:REST|COUNTER4|TEXT:0")
    LOGAPPEND("ARENA_DISTANCES:*|ARENA_ACTIVITY:*")                                          
	LOGRUN()

COMPLETE


ACTION RECOVERY_TEST
    
    SET(COUNTER1,COUNTER_INC)							# INC_rements the time_bin counter
    SET(COUNTER3,COUNTER_INC)							# INC_rements the trial counter

	LOGDATA(DATA_SNAPSHOT,"begin")                      # DATA_SNAPSHOT records info at the specific time indicated. Here the data at the beginning of the trial is recorded for later comparison with the next SNAPSHOT. You can change the name by editing inside the "".
    
    LIGHTS(LIGHT1,RED)
    
	IF VIBRATE = 1
    	INVOKE(VIBRATION)
    ENDIF
    
    IF VIBRATE = 0
		INVOKE(OPTO_FLASH)
    ENDIF
    
	WAIT(SAMPLE_TIME_SECS)
    
    LIGHTS(LIGHT1,OFF)

	LOGDATA(DATA_SNAPSHOT,"end")                        # Recording info at the end of trial. Here the data recorded is compared to the previous SNAPSHOT to give your data during the this previous time slot.
	LOGDATA(DATA_SELECT,"begin")                        # Data select command pulls the data from the named SNAPSHOT begin above.
	LOGDATA(DATA_DELTA,"end")                           # Data delta command does the calculation between the first SNAPSHOT in the series to the next one. In this SNAPSHOT "begin" is substracted from the SNAPSHOT "end" to give data variables.

 	LOGCREATE("RUNTIME|APPARATUS_ID|COUNTER5|SUBJECT_ID|TEMPERATURE1")
	LOGAPPEND("COUNTER1|COUNTER2|COUNTER3|TEXT:RECOVERY|TEXT:0|TEXT:0")
    LOGAPPEND("ARENA_DISTANCES:*|ARENA_ACTIVITY:*")                                          
	LOGRUN()

COMPLETE
	

#########################################################

# Utility actions

ACTION VIBRATION

	 MOTORCOMMAND("U0 D512 M232")
     
COMPLETE


ACTION OPTO_ON

	SET(VOLTAGE4,ON)                    # enables output of voltage on output 4 of CN5
	SET(VOLTAGE_LEVEL,OPTO_BRIGHTNESS)  # sets brightness level
    ZCOMMAND("C2#0")          			# turns light on
    
COMPLETE


ACTION OPTO_FLASH

	ZCOMMAND("C2#1 P15 C2#0")                           # P variable sets length of flash off
    
COMPLETE


ACTION DARK
    
    LIGHTS(ALL,OFF)

	SET(GPO6,0)
	SET(GPO7,0)
	SET(GPO8,0)

COMPLETE


ACTION LT_WHITE
    
    LIGHTS(ALL,OFF)

	SET(GPO6,1)
	SET(GPO7,1)
	SET(GPO8,1)

COMPLETE


#########################################################

# Actions logging well headers and loading arenas

ACTION WELL_6

	LOAD(ARENAS,"6well.bmp")				# this bitmap is required in your assets directory

    LOGAPPEND("TEXT:A1|TEXT:A2|TEXT:A3|TEXT:A4|TEXT:A5|TEXT:A6")
    LOGAPPEND("TEXT:A1MSD|TEXT:A2MSD|TEXT:A3MSD|TEXT:A4MSD|TEXT:A5MSD|TEXT:A6MSD")

COMPLETE


ACTION WELL_12

	LOAD(ARENAS,"12well.bmp")				# this bitmap is required in your assets directory

    LOGAPPEND("TEXT:A1|TEXT:A2|TEXT:A3|TEXT:A4")
    LOGAPPEND("TEXT:B1|TEXT:B2|TEXT:B3|TEXT:B4")
    LOGAPPEND("TEXT:C1|TEXT:C2|TEXT:C3|TEXT:C4")
    
    LOGAPPEND("TEXT:A1MSD|TEXT:A2MSD|TEXT:A3MSD|TEXT:A4MSD")
    LOGAPPEND("TEXT:B1MSD|TEXT:B2MSD|TEXT:B3MSD|TEXT:B4MSD")
    LOGAPPEND("TEXT:C1MSD|TEXT:C2MSD|TEXT:C3MSD|TEXT:C4MSD")
    LOGAPPEND("TEXT:D1MSD|TEXT:D2MSD|TEXT:D3MSD|TEXT:D4MSD")

COMPLETE


ACTION WELL_24

	LOAD(ARENAS,"24wellz.bmp")				# this bitmap is required in your assets directory

    LOGAPPEND("TEXT:A1|TEXT:A2|TEXT:A3|TEXT:A4|TEXT:A5|TEXT:A6")
    LOGAPPEND("TEXT:B1|TEXT:B2|TEXT:B3|TEXT:B4|TEXT:B5|TEXT:B6")
    LOGAPPEND("TEXT:C1|TEXT:C2|TEXT:C3|TEXT:C4|TEXT:C5|TEXT:C6")
    LOGAPPEND("TEXT:D1|TEXT:D2|TEXT:D3|TEXT:D4|TEXT:D5|TEXT:D6")
    
    LOGAPPEND("TEXT:A1MSD|TEXT:A2MSD|TEXT:A3MSD|TEXT:A4MSD|TEXT:A5MSD|TEXT:A6MSD")
    LOGAPPEND("TEXT:B1MSD|TEXT:B2MSD|TEXT:B3MSD|TEXT:B4MSD|TEXT:B5MSD|TEXT:B6MSD")
    LOGAPPEND("TEXT:C1MSD|TEXT:C2MSD|TEXT:C3MSD|TEXT:C4MSD|TEXT:C5MSD|TEXT:C6MSD")
    LOGAPPEND("TEXT:D1MSD|TEXT:D2MSD|TEXT:D3MSD|TEXT:D4MSD|TEXT:D5MSD|TEXT:D6MSD")

COMPLETE


ACTION WELL_48

	LOAD(ARENAS,"optogen_48_szy.bmp")				# this bitmap is required in your assets directory

    LOGAPPEND("TEXT:A1|TEXT:A2|TEXT:A3|TEXT:A4|TEXT:A5|TEXT:A6")
    LOGAPPEND("TEXT:A7|TEXT:A8")
    LOGAPPEND("TEXT:B1|TEXT:B2|TEXT:B3|TEXT:B4|TEXT:B5|TEXT:B6")
    LOGAPPEND("TEXT:B7|TEXT:B8")
    LOGAPPEND("TEXT:C1|TEXT:C2|TEXT:C3|TEXT:C4|TEXT:C5|TEXT:C6")
    LOGAPPEND("TEXT:C7|TEXT:C8")
    LOGAPPEND("TEXT:D1|TEXT:D2|TEXT:D3|TEXT:D4|TEXT:D5|TEXT:D6")
    LOGAPPEND("TEXT:D7|TEXT:D8")
    LOGAPPEND("TEXT:E1|TEXT:E2|TEXT:E3|TEXT:E4|TEXT:E5|TEXT:E6")
    LOGAPPEND("TEXT:E7|TEXT:E8")
    LOGAPPEND("TEXT:F1|TEXT:F2|TEXT:F3|TEXT:F4|TEXT:F5|TEXT:F6")
    LOGAPPEND("TEXT:F7|TEXT:F8")
    
    LOGAPPEND("TEXT:A1MSD|TEXT:A2MSD|TEXT:A3MSD|TEXT:A4MSD|TEXT:A5MSD|TEXT:A6MSD")
    LOGAPPEND("TEXT:A7MSD|TEXT:A8MSD")
    LOGAPPEND("TEXT:B1MSD|TEXT:B2MSD|TEXT:B3MSD|TEXT:B4MSD|TEXT:B5MSD|TEXT:B6MSD")
    LOGAPPEND("TEXT:B7MSD|TEXT:B8MSD")
    LOGAPPEND("TEXT:C1MSD|TEXT:C2MSD|TEXT:C3MSD|TEXT:C4MSD|TEXT:C5MSD|TEXT:C6MSD")
    LOGAPPEND("TEXT:C7MSD|TEXT:C8MSD")
    LOGAPPEND("TEXT:D1MSD|TEXT:D2MSD|TEXT:D3MSD|TEXT:D4MSD|TEXT:D5MSD|TEXT:D6MSD")
    LOGAPPEND("TEXT:D7MSD|TEXT:D8MSD")
    LOGAPPEND("TEXT:E1MSD|TEXT:E2MSD|TEXT:E3MSD|TEXT:E4MSD|TEXT:E5MSD|TEXT:E6MSD")
    LOGAPPEND("TEXT:E7MSD|TEXT:E8MSD")
    LOGAPPEND("TEXT:F1MSD|TEXT:F2MSD|TEXT:F3MSD|TEXT:F4MSD|TEXT:F5MSD|TEXT:F6MSD")
    LOGAPPEND("TEXT:F7MSD|TEXT:F8MSD")
  
COMPLETE


ACTION WELL_96

	LOAD(ARENAS,"96well.bmp")				# this bitmap is required in your assets directory

    LOGAPPEND("TEXT:A1|TEXT:A2|TEXT:A3|TEXT:A4|TEXT:A5|TEXT:A6")
    LOGAPPEND("TEXT:A7|TEXT:A8|TEXT:A9|TEXT:A10|TEXT:A11|TEXT:A12")
    LOGAPPEND("TEXT:B1|TEXT:B2|TEXT:B3|TEXT:B4|TEXT:B5|TEXT:B6")
    LOGAPPEND("TEXT:B7|TEXT:B8|TEXT:B9|TEXT:B10|TEXT:B11|TEXT:B12")
    LOGAPPEND("TEXT:C1|TEXT:C2|TEXT:C3|TEXT:C4|TEXT:C5|TEXT:C6")
    LOGAPPEND("TEXT:C7|TEXT:C8|TEXT:C9|TEXT:C10|TEXT:C11|TEXT:C12")
    LOGAPPEND("TEXT:D1|TEXT:D2|TEXT:D3|TEXT:D4|TEXT:D5|TEXT:D6")
    LOGAPPEND("TEXT:D7|TEXT:D8|TEXT:D9|TEXT:D10|TEXT:D11|TEXT:D12")
    LOGAPPEND("TEXT:E1|TEXT:E2|TEXT:E3|TEXT:E4|TEXT:E5|TEXT:E6")
    LOGAPPEND("TEXT:E7|TEXT:E8|TEXT:E9|TEXT:E10|TEXT:E11|TEXT:E12")
    LOGAPPEND("TEXT:F1|TEXT:F2|TEXT:F3|TEXT:F4|TEXT:F5|TEXT:F6")
    LOGAPPEND("TEXT:F7|TEXT:F8|TEXT:F9|TEXT:F10|TEXT:F11|TEXT:F12")
    LOGAPPEND("TEXT:G1|TEXT:G2|TEXT:G3|TEXT:G4|TEXT:G5|TEXT:G6")
    LOGAPPEND("TEXT:G7|TEXT:G8|TEXT:G9|TEXT:G10|TEXT:G11|TEXT:G12")
    LOGAPPEND("TEXT:H1|TEXT:H2|TEXT:H3|TEXT:H4|TEXT:H5|TEXT:H6")
    LOGAPPEND("TEXT:H7|TEXT:H8|TEXT:H9|TEXT:H10|TEXT:H11|TEXT:H12")
    
    LOGAPPEND("TEXT:A1MSD|TEXT:A2MSD|TEXT:A3MSD|TEXT:A4MSD|TEXT:A5MSD|TEXT:A6MSD")
    LOGAPPEND("TEXT:A7MSD|TEXT:A8MSD|TEXT:A9MSD|TEXT:A10MSD|TEXT:A11MSD|TEXT:A12MSD")
    LOGAPPEND("TEXT:B1MSD|TEXT:B2MSD|TEXT:B3MSD|TEXT:B4MSD|TEXT:B5MSD|TEXT:B6MSD")
    LOGAPPEND("TEXT:B7MSD|TEXT:B8MSD|TEXT:B9MSD|TEXT:B10MSD|TEXT:B11MSD|TEXT:B12MSD")
    LOGAPPEND("TEXT:C1MSD|TEXT:C2MSD|TEXT:C3MSD|TEXT:C4MSD|TEXT:C5MSD|TEXT:C6MSD")
    LOGAPPEND("TEXT:C7MSD|TEXT:C8MSD|TEXT:C9MSD|TEXT:C10MSD|TEXT:C11MSD|TEXT:C12MSD")
    LOGAPPEND("TEXT:D1MSD|TEXT:D2MSD|TEXT:D3MSD|TEXT:D4MSD|TEXT:D5MSD|TEXT:D6MSD")
    LOGAPPEND("TEXT:D7MSD|TEXT:D8MSD|TEXT:D9MSD|TEXT:D10MSD|TEXT:D11MSD|TEXT:D12MSD")
    LOGAPPEND("TEXT:E1MSD|TEXT:E2MSD|TEXT:E3MSD|TEXT:E4MSD|TEXT:E5MSD|TEXT:E6MSD")
    LOGAPPEND("TEXT:E7MSD|TEXT:E8MSD|TEXT:E9MSD|TEXT:E10MSD|TEXT:E11MSD|TEXT:E12MSD")
    LOGAPPEND("TEXT:F1MSD|TEXT:F2MSD|TEXT:F3MSD|TEXT:F4MSD|TEXT:F5MSD|TEXT:F6MSD")
    LOGAPPEND("TEXT:F7MSD|TEXT:F8MSD|TEXT:F9MSD|TEXT:F10MSD|TEXT:F11MSD|TEXT:F12MSD")
    LOGAPPEND("TEXT:G1MSD|TEXT:G2MSD|TEXT:G3MSD|TEXT:G4MSD|TEXT:G5MSD|TEXT:G6MSD")
    LOGAPPEND("TEXT:G7MSD|TEXT:G8MSD|TEXT:G9MSD|TEXT:G10MSD|TEXT:G11MSD|TEXT:G12MSD")
    LOGAPPEND("TEXT:H1MSD|TEXT:H2MSD|TEXT:H3MSD|TEXT:H4MSD|TEXT:H5MSD|TEXT:H6MSD")
    LOGAPPEND("TEXT:H7MSD|TEXT:H8MSD|TEXT:H9MSD|TEXT:H10MSD|TEXT:H11MSD|TEXT:H12MSD")

COMPLETE
