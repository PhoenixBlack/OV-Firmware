////////////////////////////////////////////////////////////////////////////////
// MAJOR MODE 1 (ASCENT)
////////////////////////////////////////////////////////////////////////////////
FUNCTION MAJOR_MODE1_TRANSFER {
	// INITIALIZE GUIDANCE LOOP
	SET TARGET_CONTROLLER TO PIDLOOP(0.0025, 0.0004, 0.003, MM1_MIN_ANGLE, MM1_STEERING_ANGLE).
	SET HEADING_COMMAND TO 90.
	SET PITCH_COMMAND TO 90.
	SET TRIM_COMMAND TO MM1_GET_TRIM().
	LOCK STEERING TO HEADING(HEADING_COMMAND,PITCH_COMMAND).
	
	// RESTART CONDITIONS
	IF RESTART {	
		IF ALTITUDE > 15000 {
			SET RESTART TO FALSE.
			TRANSFER_MODE(1,5).
		} ELSE IF ALTITUDE > 6000 {
			SET RESTART TO FALSE.
			TRANSFER_MODE(1,4).
		}
		IF (MAXTHRUST < MM1_FULL_THRUST) {
			SET RESTART TO FALSE.
			TRANSFER_MODE(1,7).
		}
	}
}

FUNCTION MAJOR_MODE1 {
	IF MINOR_MODE = 0 { // PRE-LAUNCH STANDBY
		SET HEADING_COMMAND TO 0.
		SET PITCH_COMMAND TO 90.
	}
	IF MINOR_MODE = 1 { // ENGINE CHECK
		SET HEADING_COMMAND TO 0.
		SET PITCH_COMMAND TO 90.
		
		IF TIME:SECONDS - MODE_TIMER > 4.0 {
			// FIXME: ADD AN ACTUAL CHECK HERE
			IF MAXTHRUST > MM1_FULL_THRUST {
				TRANSFER_MODE(1,2).
				STAGE.
			} ELSE {
				PUSH_EVENT(EVENT_ENG_FAIL).
				TRANSFER_MODE(1,0).
			}
		}
	}
	IF MINOR_MODE = 2 { // TOWER CLEAR
		SET HEADING_COMMAND TO 0.
		SET PITCH_COMMAND TO 90.
		
		IF TIME:SECONDS - MODE_TIMER > 4.0 {
			TRANSFER_MODE(1,3).
		}
	}
	IF MINOR_MODE = 3 { // ROTATE TO HEADING
		SET STEERING_CONST TO (TIME:SECONDS - MODE_TIMER)/12.0.
		SET HEADING_COMMAND TO 90*MIN(MAX(STEERING_CONST,0),1).
		SET PITCH_COMMAND TO 90 - 10*MIN(MAX(STEERING_CONST,0),1).
		
		IF ALTITUDE > 6000 {
			TRANSFER_MODE(1,4).
		}
	}
	IF MINOR_MODE = 4 { // OPEN-LOOP STEERING
		SET HEADING_COMMAND TO 90.
		SET STEERING_CONST TO (ALTITUDE-6000)/9000.
		SET PITCH_COMMAND TO 80 - (80 - MM1_STEERING_ANGLE)*MIN(MAX(STEERING_CONST,0),1).
		
		IF ALTITUDE > 15000 {
			TRANSFER_MODE(1,5).
		}
	}
	IF (MINOR_MODE = 5) OR (MINOR_MODE = 6) OR (MINOR_MODE = 7) { // MAIN GUIDANCE
		SET HEADING_COMMAND TO 90.
		SET PITCH_COMMAND TO TARGET_CONTROLLER:UPDATE(TIME:SECONDS, SHIP:APOAPSIS - 120000).

		IF (MINOR_MODE = 5) AND (MAXTHRUST < MM1_FULL_THRUST) { // READY SEP
			TRANSFER_MODE(1,6).
		}
		IF (MINOR_MODE = 6) AND (TIME:SECONDS - MODE_TIMER > 2.0) { // PERFORM SEP
			TRANSFER_MODE(1,7).
			STAGE.
		}
		IF SHIP:PERIAPSIS > MM1_CUTOFF_PER { // CUTOFF POINT
			TRANSFER_MODE(1,8).
		}
	}
	IF MINOR_MODE = 8 { // STANDBY
		IF TIME:SECONDS - MODE_TIMER > 4.0 {
			STAGE.
			TRANSFER_MODE(1,9).
		}
	}
	IF MINOR_MODE = 9 { // SEPARATE
		RCS ON.
		SET SHIP:CONTROL:TOP TO 1.0.
		IF TIME:SECONDS - MODE_TIMER > 12.0 {
			RCS OFF.
			SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
			TRANSFER_MODE(2,0).
		}
	}
	
	// CHECK ABORT TYPE
	SET ABORT_TYPE TO 2. // DITCH ABORT
	IF AIRSPEED > (2214-300) { // VELOCITY ENOUGH FOR ABORT TO ORBIT
		SET ABORT_TYPE TO 1. // ABORT TO ORBIT
	}
	IF (RUNWAY:DISTANCE < 100000) AND (MINOR_MODE >= 4) AND (ALTITUDE > 12800) { // CLOSE ENOUGH TO LAUNCH SITE
		SET ABORT_TYPE TO 0. // RETURN TO LAUNCH SITE
	}
	
	// GENERATE ABORT SIGNAL
	IF (MINOR_MODE >= 2) AND (MINOR_MODE <= 7) {
		IF MAXTHRUST < 100 {
			PUSH_EVENT(EVENT_ABORT).
			TRANSFER_MODE(5, ABORT_TYPE).
		}
	}
	
	// THROTTLE LOOP
	SET ACC TO SHIP:SENSORS:ACC:MAG.
	IF MINOR_MODE = 0 { 
		LOCK THROTTLE TO 0.0.
	} ELSE IF MINOR_MODE = 1 {
		LOCK THROTTLE TO MIN(1.0, (TIME:SECONDS - MODE_TIMER)/3.0).
	} ELSE IF MINOR_MODE < 8 {
		// DEFINE MAX THROTTLE BASED ON CURRENT ACCELERATION
		SET MAX_THRO TO 1.0 - MIN(MAX((ACC - 15.00)/20.00, 0), 0.50).
		// DEFINE DECREASE IN THROTTLE DUE TO HIGH Q
		SET THRO_Q TO MIN(MAX((SHIP:Q - 0.15)/0.05, 0), 0.50).
	
		LOCK THROTTLE TO MIN(1.0 - THRO_Q, MAX_THRO).
	} ELSE {
		LOCK THROTTLE TO 0.0.
	}
	
	// TRIM LOOP
	SET PITCH_OUTPUT TO STEERINGMANAGER:PITCHPID:OUTPUT.
	IF MINOR_MODE >= 3 {
		IF PITCH_OUTPUT > 0.10 {
			SET TRIM_COMMAND TO MAX(-16.0, TRIM_COMMAND - 0.50*DT).
		}
		IF PITCH_OUTPUT < -0.10 {
			SET TRIM_COMMAND TO MIN( -4.0, TRIM_COMMAND + 0.50*DT).
		}
		//MM1_SET_TRIM(TRIM_COMMAND).
	} ELSE {
		SET TRIM_COMMAND TO MM1_GET_TRIM().
		//MM1_SET_TRIM(-5.0).
	}

	// DISPLAY OUTPUT
	IF UI_UPDATE {
		PRINT_VAR(0, "CMD",	"DEG",	4, ROUND(PITCH_COMMAND,0),			0,0).
		PRINT_VAR(1, "Q",	"KPA",	4, ROUND(SHIP:Q*100,1),				14,0).
		PRINT_VAR(2, "THR",	"KN",	4, ROUND(MAXTHRUST,0),				0,1).
		PRINT_VAR(3, "M",	"T",	4, ROUND(MASS,1),					14,1).
		PRINT_VAR(4, "ALT",	"M",	7, ROUND(ALTITUDE/100,0)*100,		0,2).
		PRINT_VAR(5, "APO",	"M",	7, ROUND(SHIP:APOAPSIS/100,0)*100,	0,3).
		PRINT_VAR(6, "PER",	"M",	7, ROUND(SHIP:PERIAPSIS/100,0)*100,	0,4).
		PRINT_VAR(7, "TRM",	"DEG",	5, ROUND(-MM1_GET_TRIM(),2),		0,5).
		PRINT_VAR(8, "P",	"DEG",	4, ROUND(PITCH_OUTPUT,2),			14,5).
		PRINT_VAR(9, "A",	"M/S2",	6, ROUND(ACC,2),					0,6).
		
		     IF ABORT_TYPE = 2 { PRINT "DITCH" AT (19,8). }
		ELSE IF ABORT_TYPE = 1 { PRINT " ATO " AT (19,8). }
		ELSE IF ABORT_TYPE = 0 { PRINT " RLTS" AT (19,8). }
		
		IF MINOR_MODE = 0 {
			PRINT "VERB 9 TO LAUNCH" AT (0,11).
		}
	}
	
	// TELEMETERY
	IF MADS_UPDATE {
		SET CM TO (SHIP:POSITION - SHIP:ROOTPART:POSITION):MAG.
		
		MADS_TELEMETRY(1, ROUND(PITCH_COMMAND,2) ).
		MADS_TELEMETRY(2, ROUND(SHIP:Q*100,2) ).
		MADS_TELEMETRY(3, ROUND(MAXTHRUST,1) ).
		MADS_TELEMETRY(4, ROUND(MASS,2) ).
		MADS_TELEMETRY(5, ROUND(SHIP:APOAPSIS,0) ).
		MADS_TELEMETRY(6, ROUND(MM1_GET_TRIM(),2) ).
		MADS_TELEMETRY(7, ABORT_TYPE ).
		MADS_TELEMETRY(8, ROUND(CM,5) ).
	}
}




////////////////////////////////////////////////////////////////////////////////
FUNCTION MM1_GET_TRIM {
	FOR S IN ADDONS:IR:ALLSERVOS {
		IF S:NAME = "Main engine" {
			RETURN S:POSITION.
		}
	}
	RETURN 0.
}

FUNCTION MM1_SET_TRIM {
	PARAMETER TRIM.

	FOR SERVO IN ADDONS:IR:ALLSERVOS {
		IF SERVO:NAME = "Main engine" {
			SERVO:MOVETO(TRIM,1).
		}
	}
}