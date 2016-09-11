////////////////////////////////////////////////////////////////////////////////
//	OV		ORBITAL VEHICLE FIRMWARE
////////////////////////////////////////////////////////////////////////////////
// LOAD OPERATING SYSTEM
RUN RTSK.

// GLOBAL HOME BASE COORDINATE (FIXME 74.4970 other end)
GLOBAL RUNWAY				TO LATLNG(-0.0486, -74.6848 - 0.10).
GLOBAL RUNWAY_ASL			TO 71.

// MAJOR MODE 1
// 	NORMAL FULL THRUST OF THE STACK (INCLUDING FIRST STAGE BOOSTERS)
GLOBAL MM1_FULL_THRUST		TO 4700.
//	ENTRY ANGLE FOR THE CLOSED LOOP ASCENT TRAJECTORY PORTION
GLOBAL MM1_STEERING_ANGLE	TO 40.
// 	MIN ALLOWED ANGLE DURING CLOSED LOOP PORTION
GLOBAL MM1_MIN_ANGLE		TO -55.
// 	RATE (%/SEC) AT WHICH THROTTLE WILL BE REDUCED TO MAINTAIN MAX-G LIMIT
GLOBAL MM1_THROTTLE_DRATE	TO 0.03.
// 	TARGET APOAPSIS
GLOBAL MM1_TARGET_APO		TO 120000.
// 	CUTOFF PERIAPSIS
GLOBAL MM1_CUTOFF_PER		TO -50000.

// MAJOR MODE 3
//	NOMINAL PRE-LANDING SPEED (USED TO COMPUTE ENERGY TARGET)
GLOBAL MM3_TARGET_SPEED		TO 115.
//	ALTITUDE OF TRANSITION TO 1 M/S GLIDE (MUST BE LESS THAN FINAL ALT)
GLOBAL MM3_GLIDE_ALT		TO 5.
// 	GLIDESLOPE ANGLE
GLOBAL MM3_GLIDE_ANG		TO 15. 
//	ALTITUDE AT WHICH GLIDESLOPE STARTS TO GRADUALLY FLARE
GLOBAL MM3_FLARE_ALT		TO 400.
//	HIGHER NUMBER = SHARPER FLARE
GLOBAL MM3_H1_PARAM			TO 100.
// 	FINAL FLARE ALTITUDE (RADAR ALTITUDE AT WHICH FINAL FLARE STARTS)
GLOBAL MM3_FINAL_ALT		TO 80.


// MAJOR MODE 6
//	TARGET POINT DISTANCE
GLOBAL MM6_TARGET_DISTANCE	TO 110000.
//	TARGET POINT ALTITUDE (ESTIMATED RESIDUAL < 2000 M)
GLOBAL MM6_TARGET_ALT		TO 28000.
//	TARGET VELOCITY	(ESTIMATED RESIDUAL < 150 M/S)
GLOBAL MM6_TARGET_SPEED		TO 800.
//	COMPENSATION BIAS FOR VERTICAL VELOCITY TO ACCOUNT FOR ROLL REVERSALS
GLOBAL MM6_VV_COMPENSATION	TO -45.0.
// MIN ANGLE OF ATTACK (POST PEAK HEATING)
GLOBAL MM6_MIN_ALPHA1		TO 25.0.
// MIN ANGLE OF ATTACK (DURING PEAK HEATING)
GLOBAL MM6_MIN_ALPHA2		TO 32.5.
// MAX ANGLE OF ATTACK
GLOBAL MM6_MAX_ALPHA		TO 43.0.
// AVERAGE EXPECTED ALPHA (FIXME)
GLOBAL MM6_AVERAGE_ALPHA	TO 35.0.
// MAX ROLL RATE
GLOBAL MM6_ROLL_RATE		TO 8.0.
// MAX PITCH RATE
GLOBAL MM6_PITCH_RATE		TO 4.0.


// MADS RECORDER TASK
FUNCTION TASK_MADS { PARAMETER DT.
	FOR NAME IN TVARS:KEYS {
		IF TVARS_CHANGED[NAME] {
			SET TVARS_CHANGED[NAME] TO FALSE.
			PROCESSOR("MADS"):CONNECTION:SENDMESSAGE(NAME+"|"+TVARS[NAME]).
		}
	}
	TASK_SCHEDULE(4, TASK_MADS@).
}

// LOAD FLIGHT SOFTWARE
RUN OV_MM1.
	TASK_FRAME().
RUN OV_MM2.
	TASK_FRAME().
RUN OV_MM3.
	TASK_FRAME().
RUN OV_MM6.
	TASK_FRAME().
	
// ADD MADS TASK
TASK_MADS(INIT).

// START THE OPERATING SYSTEM
ENTRYPOINT().
