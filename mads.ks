//CHAR(a)

// INITIALIZE TERMINAL
CLEARSCREEN.
SET TERMINAL:CHARWIDTH TO 12.
SET TERMINAL:CHARHEIGHT TO 12.
SET TERMINAL:WIDTH TO 20.
SET TERMINAL:HEIGHT TO 8.

// LOCATION OF KSC TO COMPUTE DOWNRANGE
SET RUNWAY TO LATLNG(-0.0486, -74.6848).

// KNOWN GPC VARIABLE NAMES
SET GPC_VARIABLES TO LEXICON().

// MADS TIMERS
SET MADS_TIMER TO LEXICON().
MADS_TIMER:ADD("TIME", 0).
MADS_TIMER:ADD("STATE", 0).
MADS_TIMER:ADD("TEMP", 0).
MADS_TIMER:ADD("ACCEL", 0).

// MADS TIME MARKER RATE
SET MADS_TIME_RATE		TO 0.5.
// MADS STATE VECTOR RATE
SET MADS_STATE_RATE		TO 2.0.
// MADS TEMPERATURE SAMPLING RATE
SET MADS_TEMP_RATE		TO 5.0.
// MADS ACCELERATION AND STRAIN SAMPLING RATE
SET MADS_ACCEL_RATE		TO 2.0.





////////////////////////////////////////////////////////////////////////////////
// OPEN A NEW DATA FILE
SET ID to 1.
UNTIL NOT EXISTS("DATA" + ID + ".MDS") {
    SET ID to ID + 1.
}
SET DATAFILE TO CREATE("DATA" + ID + ".MDS").

// SCAN ALL SENSORS
SET SENSOR_NAMES TO LIST().
SET SENSORS TO LIST().
SET SENSOR_POS TO LIST().
FOR PART IN SHIP:PARTS {
	SET PREFIX TO "".
	
	IF (PART:NAME = "sensorThermometer")	{ SET PREFIX TO "T_". }
	IF (PART:NAME = "sensorAccelerometer")	{ SET PREFIX TO "A_". }

	IF PREFIX <> "" {
		SET SENSOR_NAME TO PREFIX + PART:TAG.
		SET SENSOR_POSITION TO (-SHIP:FACING) * (PART:POSITION - SHIP:ROOTPART:POSITION).
	
		// ADD THE SENSOR SO LIST IS SORTED
		FOR IDX IN RANGE(SENSOR_NAMES:LENGTH) {
			IF SENSOR_NAME < SENSOR_NAMES[IDX] {
				SENSOR_NAMES:INSERT(IDX, SENSOR_NAME).
				SENSORS:INSERT(IDX, PART).
				SENSOR_POS:INSERT(IDX, SENSOR_POSITION).
				BREAK.
			}
		}
		IF NOT SENSOR_NAMES:CONTAINS(SENSOR_NAME) {
			SENSOR_NAMES:ADD(SENSOR_NAME).
			SENSORS:ADD(PART).
			SENSOR_POS:ADD(SENSOR_POSITION).
		}
	}
}




////////////////////////////////////////////////////////////////////////////////
// TOGGLE MADS ON/OFF
SET ACTIVE TO FALSE.
ON AG6 {
	TOGGLE ACTIVE.
	PRESERVE.
}

// GET VALUE INDEX AS TELEMETRY INDEX
FUNCTION TEL_IDX {
	PARAMETER N.

	IF N < 11 {
		RETURN N.
	} ELSE IF N < 43 {
		RETURN N+1.
	} ELSE {
		RETURN N+2.
	}
}

// WRITE ALL PACKETS FOR MADS-SPECIFIC VARIABLES
DATAFILE:WRITE("!" + 0 + "TIME    ").
DATAFILE:WRITE("!" + 1 + "DOWNRNGE").
DATAFILE:WRITE("!" + 2 + "VELOCITY").
DATAFILE:WRITE("!" + 3 + "ALTITUDE").

SET GPC_FIRST_IDX TO 4.
FOR IDX IN RANGE(SENSOR_NAMES:LENGTH) {
	PRINT "SENSOR " + SENSOR_NAMES[IDX].

	LOCAL VALUE_IDX IS IDX + 4.
	DATAFILE:WRITE("!" + VALUE_IDX + SENSOR_NAMES[IDX]:PADRIGHT(8):SUBSTRING(0,8)).
	IF VALUE_IDX >= GPC_FIRST_IDX {
		SET GPC_FIRST_IDX TO VALUE_IDX + 1.
	}
}

// DISPLAY USER INTERFACE
WAIT 1.0.
CLEARSCREEN.
PRINT "MODULAR DATA SYSTEM" AT (0,0).
PRINT "    ACTIVE:" AT (0,2).
PRINT "      FILE:" AT (0,3).
PRINT "   PACKETS:" AT (0,4).
PRINT "FREE SPACE:" AT (0,5).
PRINT "  CAPACITY:" AT (0,6).

// TELEMETRY/DATA LOOP
SET PACKETS TO 0.
UNTIL FALSE {	
	// WRITE TIME REFERENCE
	IF ACTIVE {
		IF TIME:SECONDS - MADS_TIMER["TIME"] > MADS_TIME_RATE {
			SET MADS_TIMER["TIME"] TO TIME:SECONDS.
			DATAFILE:WRITE(CHAR(0+58) + ROUND(MISSIONTIME,3)).
		}
	}
	
	// WRITE STATE VECTOR
	IF ACTIVE {
		IF TIME:SECONDS - MADS_TIMER["STATE"] > MADS_STATE_RATE {
			SET MADS_TIMER["STATE"] TO TIME:SECONDS.
			DATAFILE:WRITE(CHAR(1+58) + ROUND(RUNWAY:DISTANCE,0)).
			DATAFILE:WRITE(CHAR(2+58) + ROUND(AIRSPEED,0)).
			DATAFILE:WRITE(CHAR(3+58) + ROUND(SHIP:ALTITUDE,0)).
		}
	}
	
	// CHECK IF OTHER SENSORS MUST BE WRITTEN
	LOCAL WRITE_TEMP IS FALSE.
	LOCAL WRITE_ACCEL IS FALSE.
	IF TIME:SECONDS - MADS_TIMER["TEMP"] > MADS_TEMP_RATE {
		SET MADS_TIMER["TEMP"] TO TIME:SECONDS.
		SET WRITE_TEMP TO TRUE.
	}
	IF TIME:SECONDS - MADS_TIMER["ACCEL"] > MADS_ACCEL_RATE {
		SET MADS_TIMER["ACCEL"] TO TIME:SECONDS.
		SET WRITE_ACCEL TO TRUE.
	}

	// QUERY ALL SENSORS
	IF ACTIVE {
		FOR IDX IN RANGE(SENSOR_NAMES:LENGTH) {
			IF SENSORS[IDX]:MODULES:CONTAINS("ModuleEnviroSensor") {
				SET VALUE TO SENSORS[IDX]:GETMODULE("ModuleEnviroSensor"):GETFIELD("display").
				LOCAL VALUE_IDX IS TEL_IDX(IDX + 4).
				
				// TURN ON SENSOR
				IF VALUE = "OFF" {
					SENSORS[IDX]:GETMODULE("ModuleEnviroSensor"):DOACTION("toggle display", TRUE ).
					SET VALUE TO "0u".
				}
				
				// FETCH STRAIN DATA
				IF SENSORS[IDX]:TAG:CONTAINS("RA") {
					SET SENSOR_POSITION TO (-SHIP:FACING) * (SENSORS[IDX]:POSITION - SHIP:ROOTPART:POSITION).
					SET STRAIN TO (SENSOR_POSITION - SENSOR_POS[IDX]):MAG*100000.
					IF STRAIN > 99999 {
						SET STRAIN TO 99999.
					}
					SET VALUE TO ROUND(STRAIN, 0) + "u".
				}
				
				// WRITE DATA
				IF SENSOR_NAMES[IDX]:CONTAINS("T_") {
					IF WRITE_TEMP {
						DATAFILE:WRITE(CHAR(VALUE_IDX+58) + VALUE:SUBSTRING(0,VALUE:LENGTH-1)).
						SET PACKETS TO PACKETS + 1.
					}
				} ELSE IF WRITE_ACCEL {
					DATAFILE:WRITE(CHAR(VALUE_IDX+58) + VALUE:SUBSTRING(0,VALUE:LENGTH-1)).
					SET PACKETS TO PACKETS + 1.
				}
			}
		}
	}
	
	// WRITE GPC PACKETS
	UNTIL CORE:MESSAGES:EMPTY {
		SET MESSAGE TO CORE:MESSAGES:POP:CONTENT.
		IF MESSAGE = "ON" {
			SET ACTIVE TO TRUE.
		} ELSE IF MESSAGE = "OFF" {
			SET ACTIVE TO FALSE.
		} ELSE {
			IF ACTIVE {
				SET GPC_DATA TO MESSAGE:SPLIT("|").
				IF GPC_DATA:LENGTH >= 2 {
					IF NOT GPC_VARIABLES:HASKEY(GPC_DATA[0]) {
						GPC_VARIABLES:ADD(GPC_DATA[0], TEL_IDX(GPC_FIRST_IDX)).
						DATAFILE:WRITE("!" + GPC_FIRST_IDX + GPC_DATA[0]:PADRIGHT(8):SUBSTRING(0,8)).
						SET GPC_FIRST_IDX TO GPC_FIRST_IDX + 1.
					}
					DATAFILE:WRITE(CHAR(GPC_VARIABLES[GPC_DATA[0]]+58) + GPC_DATA[1]).
					SET PACKETS TO PACKETS + 1.
				}
			}
		}
	}

	// PRINT STATUS
	IF ACTIVE {
		PRINT "ON " AT (12,2).
	} ELSE {
		PRINT "OFF" AT (12,2).
	}
	PRINT ID AT (12,3).
	PRINT PACKETS AT (12,4).
	PRINT "      " AT (12,5).
	PRINT (PROCESSOR("MADS"):VOLUME():FREESPACE+""):PADLEFT(7) AT (12,5).
	PRINT (PROCESSOR("MADS"):VOLUME():CAPACITY+""):PADLEFT(7) AT (12,6).
}