////////////////////////////////////////////////////////////////////////////////
// MAJOR MODE 6 (REENTRY)
////////////////////////////////////////////////////////////////////////////////
FUNCTION MAJOR_MODE6_TRANSFER {
	// INITIALIZE CONTROLLERS
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
	SET ROLL_RATE_MOD TO 1.
	
	// RUN GUIDANCE AT LEAST ONCE TO INITIALIZE ALL VARS
	SET DT TO 0.1.
	MM6_REENTRY_GUIDANCE().
	
	// INITIAL MODE TRANSFER
	IF (MINOR_MODE = 0) AND (SHIP:PERIAPSIS < 70000) {
		SET MINOR_MODE TO 3.
	}
	
	// RESET DOWNRANGE ESTIMATION
	SET DR_DT TO 0.
	SET EI_ESTIMATE TO TIME:SECONDS.
	SET EI_DOWNRANGE TO 0.
}

FUNCTION MM6_REENTRY_BURN {
	// ESTIMATE DOWNRANGE AT WHICH EI IS LOCATED
	LOCAL DT IS 0.1.
	LOCAL R1 IS (SHIP:BODY:ALTITUDEOF(POSITIONAT(SHIP, EI_ESTIMATE - DT)) - 70000)^2.
	LOCAL R2 IS (SHIP:BODY:ALTITUDEOF(POSITIONAT(SHIP, EI_ESTIMATE + DT)) - 70000)^2.
	SET DR_DT TO 0.00005*(R2 - R1)/DT.
	SET EI_ESTIMATE TO MAX(TIME:SECONDS, EI_ESTIMATE + DR_DT*0.10).
	IF SHIP:PERIAPSIS > 60000 {
		SET EI_ESTIMATE TO TIME:SECONDS.
	}

	// CALCULATE EI DOWNRANGE
	SET EI_POSITION TO SHIP:BODY:GEOPOSITIONOF(POSITIONAT(SHIP, EI_ESTIMATE)).
	SET EI_DOWNRANGE TO ABS( BODY("KERBIN"):RADIUS * CONSTANT:PI*(EI_POSITION:LNG - RUNWAY:LNG)/180.0 ).

	// FIXME
	IF MINOR_MODE = 1 { // BURN ARMED
		//IF (RUNWAY:DISTANCE < (MM6_BURN_DISTANCE+20000)) {
			TRANSFER_MODE(6,2).
		//}
	} ELSE IF MINOR_MODE = 2 { // ENTRY BURN
		//IF (RUNWAY:DISTANCE < MM6_BURN_DISTANCE) AND (SHIP:PERIAPSIS > -50000) {
			//RCS OFF.
			//LOCK THROTTLE TO 0.3.
		//} ELSE {
			//LOCK THROTTLE TO 0.0.
			//IF (SHIP:PERIAPSIS < -40000) {
			//	RCS ON.
			//	CLEARSCREEN.
			//	UI_HEADER().
			//	WAIT 2.0.
			//	TRANSFER_MODE(6,3).
			//}
		//}
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
	// ALTITUDE RESIDUAL TO TARGET POINT
	SET H  TO ALTITUDE-MM6_TARGET_ALT.
	
	// REFERENCE TIME TO TARGET POINT (DISTANCE-BASED TIME)
	//
	//	THIS TIME INDICATES IN HOW MANY SECONDS THE TARGET POINT WOULD BE
	//	REACHED IF THE CURRENT DRAG LEVEL REMAINS THE SAME. THIS VALUE IS
	//	USED AS AN APPROXIMATION OF TRAVEL TIME REMAINING ON THE RE-ENTRY
	//	PROFILE BASED ON VEHICLE MOTION
	//
	//	THIS VALUE IS USEFUL AS IT GRADUALLY DECREASES OVER TIME WITHOUT
	//	SIGNIFICANT IMPACT FROM THE VEHICLE TRAJECTORY, BUT VEHICLE
	//	STILL AFFECTS IT BY ITS PERFORMANCE (CURRENT DRAG IS USED AS AN
	//	APPROXIMATION FOR TRAJECTORY DRAG)
	//
	SET T0 TO MAX(1,  -(-V + SQRT(MAX(0,V*V - 2*DRAG_CUR*D)))/DRAG_CUR ).
	
	// REFERENCE TIME TO TARGET POINT (VELOCITY-BASED TIME)
	//
	//	THIS TIME INDICATES HOW MANY SECONDS ARE LEFT UNTIL ZERO VELOCITY
	//	RESIDUALS ARE REACHED. THIS IS USED AS THE CONTROL PARAMETER FOR
	//	THE RE-ENTRY AS THIS VALUE HIGHLY DEPENDS ON CURRENT DRAG VALUE
	//	AND IS SIGNIFICANTLY MORE SENSITIVE TO VEHICLE DRAGON THAN T0.
	//
	//	TERMINAL GUIDANCE IS FORMULATED AS BOTH T0 AND T CONVERGING TO ZERO
	//	AT THE TARGET POINT. ITERATIVELY THE VEHICLE ATTEMPTS TO MATCH
	//	CURRENT VELOCITY DECREASE WITH THE CURRENT DISTANCE DECREASE BY
	//	BALLANCING T0 AGAINST T
	//
	//SET T1 TO MAX(15, MIN(400,V)/7.0 -(V-400)/(DRAG_CUR) ).
	//SET T  TO MAX(15, MIN(T1, -V/(DRAG_CUR) ) ).
	SET T  TO MAX(15, -V/(DRAG_CUR) ).
	// TEST (NOT USED IN GUIDANCE)
	SET T1 TO MAX(15, MIN(400,V)/7.0 + MAX(0,-(V-400)/(DRAG_CUR)) ).
	
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
	SET MIN_AOA TO MIN(MM6_BASE_AOA - 7.5, 25 + 7.5*MIN(1,MAX(0, (MACH - 4.50)/0.4 )) ).

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
	
	// RATE LIMIT THE ROLL COMMAND. REDUCE THE ROLL RATE FOR SMALL ERROR
	IF ABS(ROLL_CMD - TGT_ROLL_CMD) < 5 {
		IF ROLL_RATE_MOD > 0.60 { // 2-SECOND EASE TO LOWER ROLL RATE
			SET ROLL_RATE_MOD TO MAX(0.60, ROLL_RATE_MOD - 0.20*DT).
		}
	} ELSE {
		IF ROLL_RATE_MOD < 1.00 { // 4-SECOND EASE TO HIGHER ROLL RATE
			SET ROLL_RATE_MOD TO MIN(1.00, ROLL_RATE_MOD + 0.10*DT).
		}
	}	
	IF ROLL_CMD < TGT_ROLL_CMD {
		SET ROLL_CMD TO MIN(TGT_ROLL_CMD, ROLL_CMD + ROLL_RATE_MOD*MM6_ROLL_REV_SPEED*DT).
	}
	IF ROLL_CMD > TGT_ROLL_CMD {
		SET ROLL_CMD TO MAX(TGT_ROLL_CMD, ROLL_CMD - ROLL_RATE_MOD*MM6_ROLL_REV_SPEED*DT).
	}
	
	// RATE LIMIT THE PITCH COMMAND
	IF PITCH_CMD < TGT_PITCH_CMD {
		SET PITCH_CMD TO MIN(TGT_PITCH_CMD, PITCH_CMD + 5*DT).
	}
	IF PITCH_CMD > TGT_PITCH_CMD {
		SET PITCH_CMD TO MAX(TGT_PITCH_CMD, PITCH_CMD - 5*DT).
	}
}

FUNCTION MAJOR_MODE6 {
	// GET ROLL REVERSAL PARAMETER
	SET ROLL_REVERSAL_PARAM TO LATITUDE.
	
	// GET CURRENT DRAG
	SET DRAG_A0 TO (AIRSPEED - PREV_AIRSPEED) / DT.
	SET PREV_AIRSPEED TO AIRSPEED.
	SET DRAG_CUR TO DRAG_CUR*0.92 + 0.08*MIN(-0.01, DRAG_A0).
	
	// GET CENTER OF MASS ESTIMATE
	SET CM TO (SHIP:POSITION - SHIP:ROOTPART:POSITION):MAG.
	SET FLAP_POS TO 0.
	IF (CM > 7.409) AND (CM <= 7.509) {
		SET FLAP_POS TO 70.0.
	} ELSE IF (CM > 7.509) AND (CM <= 7.748) {
		SET FLAP_POS TO -677.79 + 99.57*CM.
	} ELSE IF (CM > 7.748) AND (CM <= 7.781) {
		SET FLAP_POS TO -2967.82 + 395.62*CM.
	}
	
	// GET COARSE MACH NUMBER ESTIMATE
	SET MACH TO 6.8*AIRSPEED/2200.

	// RUN GUIDANCE
	IF MINOR_MODE = 0 { // MONITOR
		WAIT 0.5. // LOW-POWER MODE
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
		IF MINOR_MODE < 3 { 
			PRINT_VAR(4, "  EI",	"SEC",	7, ROUND(EI_ESTIMATE - TIME:SECONDS,1),	0,3).
			PRINT_VAR(5, "ERNG",	"M",	7, ROUND(EI_DOWNRANGE/100,0)*100,		0,4).
			PRINT_VAR(6, "  DT",	"M/S",	7, ROUND(MIN(999,DR_DT),1),					0,5).
			PRINT_VAR(7, " HEI",	"M",	7, ROUND(SHIP:BODY:ALTITUDEOF(POSITIONAT(SHIP,EI_ESTIMATE)),0),0,6).
			PRINT_VAR(8, " REF",	"DEG",	7, ROUND(EI_POSITION:LAT,3),			0,7).
		} ELSE {
			IF T < 1000.0 {
				PRINT_VAR(4, "TIME",	"SEC",	7, ROUND(T,1),						0,3).
			} ELSE {
				PRINT_VAR(4, "TIME",	"SEC",	7, "-----",							0,3).
			}
			PRINT_VAR(5, "TREF",	"SEC",	7, ROUND(T0,1),							0,4).
			PRINT_VAR(6, "DRAG",	"M/S2",	7, ROUND(DRAG_CUR,2),					0,5).
			PRINT_VAR(7, "VERT",	"M/S",	7, ROUND(VERTICALSPEED,1),				0,6).
			PRINT_VAR(8, "VREF",	"M/S",	7, ROUND(VV_REF,1),						0,7).
		}
		PRINT_VAR(9, "R",		"",		5, ROUND(ROLL_REVERSAL_PARAM,2),		17,7).
		PRINT_VAR(10,"CM",		"M",	5, ROUND(CM,3),							0,8).
		PRINT_VAR(11,"FLAP",	"DEG",	4, ROUND(FLAP_POS,1),					11,8).

		//PRINT_VAR(12, "Q",		"KPA",	4, ROUND(SHIP:Q*100,1),					11,0).
		
		IF MINOR_MODE = 0 {
			PRINT "VERB 9 ARM REENTRY BURN" AT (0,11).
		}
	}	

	// TELEMETERY
	IF MADS_UPDATE {
		MADS_TELEMETRY(1, ROUND(T0,2) ).
		MADS_TELEMETRY(2, ROUND(DRAG_CUR,2) ).
		MADS_TELEMETRY(3, ROUND(VERTICALSPEED,2) ).
		MADS_TELEMETRY(4, ROUND(VV_REF,2) ).
		MADS_TELEMETRY(5, ROUND(CM,3) ).
		MADS_TELEMETRY(6, ROUND(PITCH_CMD,2) ).
		MADS_TELEMETRY(7, ROUND(ROLL_CMD,2) ).
		MADS_TELEMETRY(8, ROUND(T,2) ).
		MADS_TELEMETRY(9, ROUND(T1,2) ).
	}
}




////////////////////////////////////////////////////////////////////////////////
FUNCTION MM6_GET_BODYFLAP {
	FOR S IN ADDONS:IR:ALLSERVOS {
		IF S:NAME = "Body flap" {
			RETURN S:POSITION.
		}
	}
	RETURN 0.
}

FUNCTION MM6_SET_BODYFLAP {
	PARAMETER TRIM.

	FOR SERVO IN ADDONS:IR:ALLSERVOS {
		IF SERVO:NAME = "Body flap" {
			SERVO:MOVETO(TRIM,1).
		}
	}
}