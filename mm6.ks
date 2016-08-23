////////////////////////////////////////////////////////////////////////////////
// MAJOR MODE 6 (REENTRY)
////////////////////////////////////////////////////////////////////////////////
FUNCTION MAJOR_MODE6_TRANSFER {
	// INITIALIZE CONTROLLERS
	//SET HDRAG_CONTROLLER TO PIDLOOP(0.35, 0.05, 0.15,  -10.0, 7.5).
	SET HDRAG_CONTROLLER TO PIDLOOP(0.350,	0.050,	0.150,	-10.0,	7.5).
	SET VDRAG_CONTROLLER TO PIDLOOP(2.000,	0.050,	2.000,	-35.0,	15.0).
	SET PREV_AIRSPEED TO AIRSPEED.
	SET DRAG_CUR TO -0.01.
	SET MACH TO 0.
	
	// ROLL REVERSAL TIMER
	SET ROLL_REVERSAL TO -10000.
	SET ROLL_SIGN TO 1.
	SET ROLL_CMD TO ROLL_SIGN*70.
	SET PITCH_CMD TO MM6_BASE_AOA.
	SET ROLL_REVERSAL_THRESHOLD TO 0.01.
	SET ROLL_REVERSAL_PARAM TO 0.
	
	// RUN GUIDANCE AT LEAST ONCE TO INITIALIZE ALL VARS
	SET DT TO 0.1.
	MM6_REENTRY_GUIDANCE().
	
	// INITIAL MODE TRANSFER
	IF (MINOR_MODE = 0) AND (SHIP:PERIAPSIS < 70000) {
		SET MINOR_MODE TO 3.
	}
}

FUNCTION MM6_REENTRY_BURN {
	IF MINOR_MODE = 1 { // BURN ARMED
		IF (RUNWAY:DISTANCE < (MM6_BURN_DISTANCE+20000)) {
			TRANSFER_MODE(6,2).
		}
	} ELSE IF MINOR_MODE = 2 { // ENTRY BURN
		IF (RUNWAY:DISTANCE < MM6_BURN_DISTANCE) AND (SHIP:PERIAPSIS > -50000) {
			RCS OFF.
			LOCK THROTTLE TO 1.0.
		} ELSE {
			LOCK THROTTLE TO 0.0.
			IF (SHIP:PERIAPSIS < -40000) {
				RCS ON.
				CLEARSCREEN.
				UI_HEADER().
				WAIT 2.0.
				TRANSFER_MODE(6,3).
			}
		}
	}
}

FUNCTION MM6_ROLL_REVERSAL {
	IF MINOR_MODE = 3 {
		TRANSFER_MODE(6,4).
	} ELSE IF MINOR_MODE = 4 {
		TRANSFER_MODE(6,5).
	} ELSE IF MINOR_MODE = 5 {
		TRANSFER_MODE(6,6).
	}
}

FUNCTION MM6_REENTRY_GUIDANCE {
	// BASIC EQUATIONS:
	// D = V T + A T^2/2
	// A = 2*(D - V*T)/(T^2)
	// H = -VV * T
	// T = (-V +- SQRT(V*V - 2*A*D))/A	
	
	// DISTANCE TO REENTRY TARGET POINT
	SET D  TO MAX(0, RUNWAY:DISTANCE - MM6_TARGET_DISTANCE).
	// VELOCITY RESIDUAL TO TARGET POINT
	SET V  TO AIRSPEED-MM6_TARGET_SPEED.
	// REFERENCE TIME TO TARGET POINT (BASED ON CURRENT DISTANCE)
	SET T0 TO MAX(1,  -(-V + SQRT(MAX(0,V*V - 2*DRAG_CUR*D)))/DRAG_CUR ).
	// REAL TIME TO TARGET POINT (BASED ON CURRENT VELOCITY). 0.95 COMPENSATES OVERSHOOT
	SET T1 TO MIN(200,V)/5.0. // FINAL BRAKING ADJUSTMENT
	SET T2 TO MAX(15, T1 -(V-200)/(DRAG_CUR) ).
	SET T  TO MAX(15, MIN(T2, -V/(DRAG_CUR) ) ).
	// ALTITUDE RESIDUAL TO TARGET POINT
	SET H  TO ALTITUDE-MM6_TARGET_ALT.
	// REFERENCE VERTICAL SPEED
	SET VV_COMPENSATION TO 45.0.
	SET VV_REF TO MIN(-25, -H/T0 - VV_COMPENSATION).
	
	// TRANSFER TO LANDING
	IF (V < 0) OR (RUNWAY:DISTANCE < MM6_TARGET_DISTANCE*0.80) {
		TRANSFER_MODE(3,1).
	}

	// IS ROLL REVERSAL REQUIRED
	IF ALTITUDE < 70000 {
		IF (ROLL_REVERSAL_PARAM > ROLL_REVERSAL_THRESHOLD) AND (ROLL_SIGN = -1) {
			SET ROLL_SIGN TO 1.
			MM6_ROLL_REVERSAL().
		}
		IF (ROLL_REVERSAL_PARAM < -ROLL_REVERSAL_THRESHOLD) AND (ROLL_SIGN = 1) {
			SET ROLL_SIGN TO -1.
			MM6_ROLL_REVERSAL().
		}
	} ELSE {
		// DETERMINE INITIAL ROLL
		IF ROLL_REVERSAL_PARAM > 0 {
			SET ROLL_SIGN TO 1.
		} ELSE {
			SET ROLL_SIGN TO -1.
		}
	}
	
	// GET MIN AOA
	SET MIN_AOA TO MIN(MM6_BASE_AOA - 7.5, 25 + 7.5*MIN(1,MAX(0, (MACH - 4.25)/0.5 )) ).
		
	// COMPUTE HDRAG, VDRAG ERROR
	SET VDRAG_DELTA TO VV_REF - VERTICALSPEED.
	SET HDRAG_DELTA TO T0 - T.
	IF T = 1 { // SPECIAL CASE: OVERSHOOTING
		SET HDRAG_DELTA TO 100.
	}
	
	// MODULATE ANGLE OF ATTACK TO CONTROL DRAG
	SET TGT_PITCH_CMD TO MAX(MIN_AOA, MM6_BASE_AOA + HDRAG_CONTROLLER:UPDATE(TIME:SECONDS, HDRAG_DELTA) ).
	// MODULATE VERTICAL VELOCITY TO CONTROL DESCENT SPEED (AND DRAG INDIRECTLY)
	SET TGT_ROLL_CMD TO ROLL_SIGN*(70 + VDRAG_CONTROLLER:UPDATE(TIME:SECONDS, VDRAG_DELTA)).
	
	// ENTRY ATTITUDE ABOVE THRESHOLD
	IF ALTITUDE > 70000 {
		SET TGT_ROLL_CMD TO 0.
	}
	
	// RATE LIMIT THE ROLL COMMAND
	IF ROLL_CMD < TGT_ROLL_CMD {
		SET ROLL_CMD TO ROLL_CMD + 6*DT. // 8
	}
	IF ROLL_CMD > TGT_ROLL_CMD {
		SET ROLL_CMD TO ROLL_CMD - 6*DT.
	}
	
	// RATE LIMIT THE PITCH COMMAND
	IF PITCH_CMD < TGT_PITCH_CMD {
		SET PITCH_CMD TO PITCH_CMD + 5*DT.
	}
	IF PITCH_CMD > TGT_PITCH_CMD {
		SET PITCH_CMD TO PITCH_CMD - 5*DT.
	}
}

FUNCTION MAJOR_MODE6 {
	// GET ROLL REVERSAL PARAMETER
	SET ROLL_REVERSAL_PARAM TO LATITUDE.
	
	// GET CURRENT DRAG
	SET DRAG_A0 TO (AIRSPEED - PREV_AIRSPEED) / DT.
	SET PREV_AIRSPEED TO AIRSPEED.
	SET DRAG_CUR TO DRAG_CUR*0.92 + 0.08*MIN(-0.01, DRAG_A0). //-SHIP:SENSORS:ACC:MAG).
	
	// GET CENTER OF MASS ESTIMATE
	SET CM TO (SHIP:POSITION - SHIP:ROOTPART:POSITION):MAG.
	SET FLAP_POS TO 0.
	IF (CM > 7.509) AND (CM <= 7.748) {
		SET FLAP_POS TO -677.79 + 99.57*CM.
	} ELSE IF (CM > 7.748) AND (CM <= 7.781) {
		SET FLAP_POS TO -2967.82 + 395.62*CM.
	}
	
	// GET COARSE MACH NUMBER ESTIMATE
	SET MACH TO 6.8*AIRSPEED/2200.

	// RUN GUIDANCE
	IF MINOR_MODE = 0 { // MONITOR
		WAIT 1.0. // LOW-POWER MODE
	} ELSE IF MINOR_MODE = 1 { // BURN ARMED
		MM6_REENTRY_BURN(). // DO REENTRY BURN
		LOCK STEERING TO -SHIP:VELOCITY:SURFACE. // RETROGRADE ATTITUDE
	} ELSE IF MINOR_MODE = 2 { // BURN ACTIVE
		MM6_REENTRY_BURN(). // DO REENTRY BURN
		LOCK STEERING TO -SHIP:VELOCITY:SURFACE. // RETROGRADE ATTITUDE
	} ELSE { // REENTRY GUIDANCE
		MM6_REENTRY_GUIDANCE().
	
		SET TARGET_DIR TO LOOKDIRUP(SHIP:VELOCITY:SURFACE, SHIP:UP:FOREVECTOR).
		LOCK STEERING TO (TARGET_DIR*R(0,0,-ROLL_CMD))*R(-PITCH_CMD,0,0).
		UNLOCK THROTTLE. // ALLOW VENTING DURING REENTRY
		//LOCK THROTTLE TO 0.0.
	}
	
	// DISPLAY OUTPUT
	IF UI_UPDATE {
		PRINT_VAR(0, " ALT",	"M",	7, ROUND(ALTITUDE/10,0)*10,				0,0).
		PRINT_VAR(1, " VEL",	"M/S",	7, ROUND(V,1),							0,1).
		PRINT_VAR(2, "M",		"",		5, ROUND(MACH,2),						17,1).
		PRINT_VAR(3, "DRNG",	"M",	7, ROUND(RUNWAY:DISTANCE/100,0)*100,	0,2).
		IF T < 1000.0 {
			PRINT_VAR(4, "TIME",	"SEC",	7, ROUND(T,1),						0,3).
		} ELSE {
			PRINT_VAR(4, "TIME",	"SEC",	7, "-----",							0,3).
		}
		PRINT_VAR(5, "TREF",	"SEC",	7, ROUND(T0,1),							0,4).
		PRINT_VAR(6, "DRAG",	"M/S2",	7, ROUND(DRAG_CUR,2),					0,5).
		PRINT_VAR(7, "VERT",	"M/S",	7, ROUND(VERTICALSPEED,1),				0,6).
		PRINT_VAR(8, "VREF",	"M/S",	7, ROUND(VV_REF,1),						0,7).
		PRINT_VAR(9, "R",		"",		5, ROUND(ROLL_REVERSAL_PARAM,2),		17,7).
		PRINT_VAR(10,"CM",		"M",	5, ROUND(CM,3),							0,8).
		PRINT_VAR(11,"FLAP",	"DEG",	4, ROUND(FLAP_POS,1),					11,8).
		
		IF T2 < 1000.0 {
			//PRINT_VAR(4, "TIME",	"SEC",	7, ROUND(T2,1),						0,8).
		} ELSE {
			//PRINT_VAR(4, "TIME",	"SEC",	7, "-----",							0,8).
		}
		
		IF MINOR_MODE = 0 {
			PRINT "VERB 9 ARM REENTRY BURN" AT (0,11).
		}
	}
}