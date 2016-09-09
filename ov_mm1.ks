////////////////////////////////////////////////////////////////////////////////
//	OV		MAJOR MODE 1 (ASCENT)
////////////////////////////////////////////////////////////////////////////////
FUNCTION MM1_ENTER {
	// INITIALIZE ASCENT STEERING
	GLOBAL ASCENT_CONTROLLER TO PIDLOOP(0.0030, 0.0003, 0.0030, MM1_MIN_ANGLE, MM1_STEERING_ANGLE).
	GLOBAL HEADING_COMMAND TO 90.
	GLOBAL PITCH_COMMAND TO 90.
	GLOBAL MAX_THROTTLE TO 1.0.
	SET CURRENT_STEERING TO HEADING(HEADING_COMMAND,PITCH_COMMAND).
	SET CURRENT_THROTTLE TO 0.0.
	
	// INITIALIZE TRIM CONTROL
	SET TRIM_COMMAND TO SERVO_GET("MAIN ENGINE").
	
	// ENABLE STEERING
	ENABLE_STEERING().
	ENABLE_THROTTLE().
	
	// INITIALIZE OTHER VARIABLES
	GLOBAL ABORT_TYPE TO 0.
	
	// CHECK RESTART CONDITIONS
	IF ALTITUDE > 15000 {
		TRANSFER_MODE(1,5).
	} ELSE IF ALTITUDE > 6000 {
		TRANSFER_MODE(1,4).
	}
	IF MINOR_MODE = 1 { // FALL BACK FROM ENGINE CHECK
		TRANSFER_MODE(1,0).
	}
	IF (MINOR_MODE > 1) AND (MAXTHRUST < MM1_FULL_THRUST) { // IN ASCENT AND HAVE LOW THRUST 
		TRANSFER_MODE(1,7).
	}
}

FUNCTION MM1_LEAVE {
	// DISABLE STEERING
	DISABLE_STEERING().
}

FUNCTION MM1_TRANSFER {
	//
}

FUNCTION MM1_GUIDANCE_TASK { PARAMETER DT.
	TASK_SCHEDULE(1, MM1_GUIDANCE_TASK@).
	
	IF MINOR_MODE = 0 { // PRE-LAUNCH STANDBY
		SET HEADING_COMMAND TO 0.
		SET PITCH_COMMAND TO 90.
	} ELSE IF MINOR_MODE = 1 { // ENGINE CHECK
		SET HEADING_COMMAND TO 0.
		SET PITCH_COMMAND TO 90.
		
		IF MODE_TIMER > 4.0 {
			LOCAL ENGINES_OK IS TRUE.
			SET ENGINES_OK TO ENGINES_OK AND (MAXTHRUST > MM1_FULL_THRUST).

			IF ENGINES_OK {
				TRANSFER_MODE(1,2).
				STAGE.
			} ELSE {
				PUSH_EVENT("101 ENG FAIL", HIGH).
				TRANSFER_MODE(1,0).
			}
		}
	} ELSE IF MINOR_MODE = 2 { // TOWER CLEAR
		SET HEADING_COMMAND TO 0.
		SET PITCH_COMMAND TO 90.
		
		IF MODE_TIMER > 4.0 {
			TRANSFER_MODE(1,3).
		}
	} ELSE IF MINOR_MODE = 3 { // ROTATE TO HEADING
		SET STEERING_CONST TO MODE_TIMER/12.0.
		SET HEADING_COMMAND TO 90*MIN(MAX(STEERING_CONST,0),1).
		SET PITCH_COMMAND TO 90 - 10*MIN(MAX(STEERING_CONST,0),1).
		
		IF ALTITUDE > 6000 {
			TRANSFER_MODE(1,4).
		}
	} ELSE IF MINOR_MODE = 4 { // OPEN-LOOP STEERING
		SET HEADING_COMMAND TO 90.
		SET STEERING_CONST TO (ALTITUDE-6000)/9000.
		SET PITCH_COMMAND TO 80 - (80 - MM1_STEERING_ANGLE)*MIN(MAX(STEERING_CONST,0),1).
		
		IF ALTITUDE > 15000 {
			TRANSFER_MODE(1,5).
		}
	} ELSE IF (MINOR_MODE = 5) OR (MINOR_MODE = 6) OR (MINOR_MODE = 7) { // MAIN GUIDANCE
		SET HEADING_COMMAND TO 90.
		SET PITCH_COMMAND TO ASCENT_CONTROLLER:UPDATE(TIME:SECONDS, SHIP:APOAPSIS - MM1_TARGET_APO).

		IF (MINOR_MODE = 5) AND (MAXTHRUST < MM1_FULL_THRUST) { // READY SEP
			TRANSFER_MODE(1,6).
		}
		IF (MINOR_MODE = 6) AND (MODE_TIMER > 2.0) { // PERFORM SEP
			TRANSFER_MODE(1,7).
			STAGE.
		}
		IF SHIP:PERIAPSIS > MM1_CUTOFF_PER { // CUTOFF POINT
			TRANSFER_MODE(1,8).
		}
	} ELSE IF MINOR_MODE = 8 { // STANDBY AND SETTLE
		IF MODE_TIMER > 4.0 {
			PUSH_EVENT("103 ET SEP", LOW).
			STAGE.
			TRANSFER_MODE(1,9).
		}
	} ELSE IF MINOR_MODE = 9 { // SEPARATE
		ENABLE_RCS().
		SET SHIP:CONTROL:TOP TO 1.0.
		IF MODE_TIMER > 12.0 {
			DISABLE_RCS().
			TRANSFER_MODE(2,0).
		}
	}
	
	// STEERING LOOP
	SET CURRENT_STEERING TO HEADING(HEADING_COMMAND, PITCH_COMMAND).

	// TRIM LOOP
	//SET PITCH_OUTPUT TO STEERINGMANAGER:PITCHPID:OUTPUT.
	//IF MINOR_MODE >= 3 {
	//	IF PITCH_OUTPUT > 0.10 {
	//		SET TRIM_COMMAND TO MAX(-16.0, TRIM_COMMAND - 0.50*DT).
	//	}
	//	IF PITCH_OUTPUT < -0.10 {
	//		SET TRIM_COMMAND TO MIN( -4.0, TRIM_COMMAND + 0.50*DT).
	//	}
	//	//MM1_SET_TRIM(TRIM_COMMAND).
	//} ELSE {
	//	SET TRIM_COMMAND TO MM1_GET_TRIM().
	//	//MM1_SET_TRIM(-5.0).
	//}
}

FUNCTION MM1_THROTTLE_TASK { PARAMETER DT.
	IF MINOR_MODE = 1 {
		TASK_SCHEDULE(1, MM1_THROTTLE_TASK@).
	} ELSE {
		TASK_SCHEDULE(3, MM1_THROTTLE_TASK@).
	}
	
	IF MINOR_MODE = 1 { // ENGINE CHECK
		SET CURRENT_THROTTLE TO MIN(1.0, MODE_TIMER/3.0).
		
	} ELSE IF (MINOR_MODE > 1) AND (MINOR_MODE < 8) { // FLIGHT THROTTLE
		// LIMIT MAX THROTTLE BASED ON ACCELERATION
		IF SHIP:SENSORS:ACC:MAG > 16.0 {
			SET MAX_THROTTLE TO MAX(0.35, MAX_THROTTLE - MM1_THROTTLE_DRATE*DT).
		}
		
		// DEFINE DECREASE IN THROTTLE DUE TO HIGH Q
		LOCAL Q_THROTTLE IS MIN(MAX((SHIP:Q - 0.15)/0.05, 0), 0.50).
	
		// SET THROTTLE LEVEL
		SET CURRENT_THROTTLE TO MIN(1.0 - Q_THROTTLE, MAX_THROTTLE).
		
	} ELSE { // OTHER MODES
		SET CURRENT_THROTTLE TO 0.0.
	}
}.

FUNCTION MM1_ABORT_TASK { PARAMETER DT.
	TASK_SCHEDULE(6, MM1_ABORT_TASK@).
	
	// DEFAULT ABORT
	SET ABORT_TYPE TO 2. // DITCH ABORT
	
	// VELOCITY ENOUGH FOR ABORT TO ORBIT
	IF AIRSPEED > (2214-300) {
		SET ABORT_TYPE TO 1. // ABORT TO ORBIT
	}
	
	// CLOSE ENOUGH TO LAUNCH SITE
	IF (RUNWAY:DISTANCE < 100000) AND (MINOR_MODE >= 4) AND (ALTITUDE > 12800) {
		SET ABORT_TYPE TO 0. // RETURN TO LAUNCH SITE
	}
	
	// GENERATE ABORT SIGNAL
	IF (MINOR_MODE >= 2) AND (MINOR_MODE <= 7) {
		IF MAXTHRUST < 100 {
			PUSH_EVENT("102 ABORT", HIGH).
			TRANSFER_MODE(5, ABORT_TYPE).
		}
	}
}.

FUNCTION MM1_UI_LO_TASK { PARAMETER DT.
	TASK_SCHEDULE(5, MM1_UI_LO_TASK@).
	
	// GUIDANCE
	UI_VARIABLE("P CMD",	"DEG",	PITCH_COMMAND, 						2,7, NUMBER,	0,0).
	UI_VARIABLE("F STG",	"KN",	MAXTHRUST, 							2,7, NUMBER,	0,1).
	UI_VARIABLE("F CMD",	"%",	CURRENT_THROTTLE*100,				2,7, NUMBER,	0,2).
	UI_VARIABLE("ACCEL",	"M/S2",	SHIP:SENSORS:ACC:MAG,				2,7, NUMBER,	0,3).
	UI_VARIABLE(" M",		"T",	MASS, 								2,5, NUMBER,	17,0).
IF MINOR_MODE >= 5 {
	UI_VARIABLE(" Q",		"KPA",	SHIP:Q*100, 						2,5, NUMBER,	17,1).
}
	
	// ALTITUDE
	UI_VARIABLE("  ALT",	"M",	ROUND(ALTITUDE/100,0)*100, 			0,7, NUMBER,	0,6).
	UI_VARIABLE("  PER",	"M",	ROUND(SHIP:PERIAPSIS/100,0)*100, 	0,7, NUMBER,	0,8).
	
	// EXTRA INFO
		 IF ABORT_TYPE = 2 { UI_VARIABLE("ABORT", "", "DITCH", 0,5,TEXT,  17,6). }
	ELSE IF ABORT_TYPE = 1 { UI_VARIABLE("ABORT", "", "ATO  ", 0,5,TEXT,  17,6). }
	ELSE IF ABORT_TYPE = 0 { UI_VARIABLE("ABORT", "", "RLTS ", 0,5,TEXT,  17,6). }
	
	// EXTRA TRIGGER CHECKS FOR DIAGNOSTIC PURPOSES
	TRIGGER_CHECK("01 HIGH Q", LOW, (SHIP:Q - 0.162) / 0.001).
}.

FUNCTION MM1_UI_HI_TASK { PARAMETER DT.
	TASK_SCHEDULE(2, MM1_UI_HI_TASK@).
	
	// GUIDANCE
IF MINOR_MODE < 5 {
	UI_VARIABLE(" Q",		"KPA",	SHIP:Q*100, 						2,5, NUMBER,	17,1).
}
	UI_VARIABLE(" TRIM",	"DEG",	-SERVO_GET("Main engine"), 			2,7, NUMBER,	0,4).
	
	// ALTITUDE
	UI_VARIABLE("  APO",	"M",	ROUND(SHIP:APOAPSIS/100,0)*100, 	0,7, NUMBER,	0,7).
}.

FUNCTION MM1_TELEMETRY_TASK { PARAMETER DT.
	//MADS_TELEMETRY(1, ROUND(PITCH_COMMAND,2) ).
	//MADS_TELEMETRY(2, ROUND(SHIP:Q*100,2) ).
	//MADS_TELEMETRY(3, ROUND(MAXTHRUST,1) ).
	//MADS_TELEMETRY(4, ROUND(MASS,2) ).
	//MADS_TELEMETRY(5, ROUND(SHIP:APOAPSIS,0) ).
	//MADS_TELEMETRY(6, ROUND(MM1_GET_TRIM(),2) ).
	//MADS_TELEMETRY(7, ABORT_TYPE ).
	
	TASK_SCHEDULE(7, MM1_TELEMETRY_TASK@).
}.

FUNCTION MM1_COMMAND {
	PARAMETER VERB, VALUE.
	
	IF VERB = 9 { // PROCEED
		TRANSFER_MODE(1,1).
		STAGE.
	}
}


////////////////////////////////////////////////////////////////////////////////
// MAJOR MODE 9
////////////////////////////////////////////////////////////////////////////////
MODE_NAMES:ADD(10, "PRE-LAUNCH HOLD ").
MODE_NAMES:ADD(11, "ENGINE CHECK    ").
MODE_NAMES:ADD(12, "TOWER CLEAR     ").
MODE_NAMES:ADD(13, "HEADING ROTATE  ").
MODE_NAMES:ADD(14, "OPEN LOOP       ").
MODE_NAMES:ADD(15, "CLOSED LOOP ST1 ").
MODE_NAMES:ADD(16, "!!STAGE SEPAR!!!").
MODE_NAMES:ADD(17, "CLOSED LOOP ST2 ").
MODE_NAMES:ADD(18, "ET COAST PHASE  ").
MODE_NAMES:ADD(19, "ET SEPARATION   ").

MODE_ENTER		(1, MM1_ENTER@).
MODE_TRANSFER	(1, MM1_TRANSFER@).
MODE_LEAVE		(1, MM1_LEAVE@).
MODE_COMMAND	(1, MM1_COMMAND@).

MODE_TASK		(1, MM1_GUIDANCE_TASK@).
MODE_TASK		(1, MM1_THROTTLE_TASK@).
MODE_TASK		(1, MM1_ABORT_TASK@).
MODE_TASK		(1, MM1_UI_LO_TASK@).
MODE_TASK		(1, MM1_UI_HI_TASK@).
MODE_TASK		(1, MM1_TELEMETRY_TASK@).
