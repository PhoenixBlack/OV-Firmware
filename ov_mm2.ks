////////////////////////////////////////////////////////////////////////////////
//	OV		MAJOR MODE 2 (ON-ORBIT)
////////////////////////////////////////////////////////////////////////////////
FUNCTION MM2_ENTER {
	// LOAD PARAMETERS
	GLOBAL DOCK_DP				TO GET_PVAR("DP", 0).
	GLOBAL DOCK_DY				TO GET_PVAR("DY", 0).
	GLOBAL DOCK_DR				TO GET_PVAR("DR", 0).
	GLOBAL DOCK_PORT			TO GET_PVAR("PORT", 0).
	GLOBAL RCS_SENSITIVITY		TO GET_PVAR("RCS_SENS", 10).
	GLOBAL USER_INPUT_MAG		TO GET_PVAR("UI_MAG", 2).
	GLOBAL APPROACH_SENSITIVITY TO GET_PVAR("APP_SENS", 50).

	GLOBAL HOLD_ATT				TO GET_PVAR("HOLD_ATT", 0).
	GLOBAL HOLD_VEL				TO GET_PVAR("HOLD_VEL", 0).
	
	// GUIDANCE VARIABLES
	GLOBAL DR_DT TO 0.
	GLOBAL APPROACH_TIME TO 0.
	GLOBAL APPROACH_VEC  TO V(0,0,0).
	GLOBAL APPROACH_VEL  TO 0.
	GLOBAL APPROACH_DIST TO 0.
	GLOBAL CURRENT_DIST  TO 0.
	GLOBAL CLOSEST_APPROACH TO TIME:SECONDS.
	GLOBAL REL_POSITION			TO V(0,0,0).
	GLOBAL REL_POSITION_SHIP	TO V(0,0,0).
	GLOBAL REL_VELOCITY			TO V(0,0,0).
	GLOBAL REL_VELOCITY_SHIP	TO V(0,0,0).
	GLOBAL TGT_ATTITUDE			TO SHIP:FACING.
	
	// ONLY USER-CONTROLLED RCS
	DISABLE_RCS().
	
	// HIGH RATE SYSTEMS SCREEN
	SET UI_SYSTEMS_SCREEN_PRIORITY TO 4.
}

FUNCTION MM2_LEAVE {
	// ENSURE RCS STAYS OFF AFTER LEAVING TOO
	DISABLE_RCS().
	DISABLE_STEERING().
	
	// RELEASE PRIORITY OVERRIDE
	SET UI_SYSTEMS_SCREEN_PRIORITY TO 0.
}

FUNCTION MM2_TRANSFER {
	IF MINOR_MODE = 2 {
		// SCHEDULE TASK
		TASK_SCHEDULE(1, MM2_DOCK_TASK@).
		
		// DISABLE HOLDS
		SET HOLD_ATT TO 0.
		SET HOLD_VEL TO 0.
		SET_PVAR("HOLD_ATT", 0).
		SET_PVAR("HOLD_VEL", 0).
		
		// INITALIZE VARIABLES
		GLOBAL REL_POSITION			TO V(0,0,0).
		GLOBAL REL_POSITION_SHIP	TO V(0,0,0).
		GLOBAL REL_VELOCITY			TO V(0,0,0).
		GLOBAL REL_VELOCITY_SHIP	TO V(0,0,0).
		GLOBAL TGT_ATTITUDE			TO SHIP:FACING.
	}
	IF MINOR_MODE = 6 {
		// SCHEDULE TASK
		TASK_SCHEDULE(1, MM2_TARGET_TRACK_TASK@).
		
		// INITALIZE VARIABLES
		GLOBAL REL_POSITION			TO V(0,0,0).
		GLOBAL REL_VELOCITY			TO V(0,0,0).
		
		// ENABLE STEERING
		ENABLE_STEERING().
	}
	IF MINOR_MODE = 7 {
		// SCHEDULE TASK
		TASK_SCHEDULE(1, MM2_RENDEZVOUS_TASK@).
		
		// INITIALIZE VARIABLES
		GLOBAL DR_DT TO 0.
		GLOBAL APPROACH_TIME TO 0.
		GLOBAL APPROACH_VEC  TO V(0,0,0).
		GLOBAL APPROACH_VEL  TO 0.
		GLOBAL APPROACH_DIST TO 0.
		GLOBAL CURRENT_DIST  TO 0.
		GLOBAL CLOSEST_APPROACH TO TIME:SECONDS.
	}
}

FUNCTION MM2_DOCK_TASK { PARAMETER DT.
	IF MINOR_MODE = 2 {
		TASK_SCHEDULE(1, MM2_DOCK_TASK@).
	} ELSE {
		RETURN.
	}

	IF HASTARGET {
		// FIND DOCKING PORT, IF SELECTED
		LOCAL PORTS IS TARGET:PARTSTAGGED("DOCK" + DOCK_PORT).		
	
		// RELATIVE POSITION/VELOCITY
		IF (DOCK_PORT = 0) OR (PORTS:LENGTH = 0) {
			SET REL_POSITION		TO TARGET:POSITION - SHIP:POSITION.
			SET REL_POSITION_SHIP	TO (-SHIP:FACING) * REL_POSITION.
			SET REL_VELOCITY		TO TARGET:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT.
			SET REL_VELOCITY_SHIP	TO (-SHIP:FACING) * REL_VELOCITY.
			SET TGT_ATTITUDE		TO TARGET:FACING.
		} ELSE {
			SET REL_POSITION		TO PORTS[0]:POSITION - SHIP:POSITION.
			SET REL_POSITION_SHIP	TO (-SHIP:FACING) * REL_POSITION.
			SET REL_VELOCITY		TO PORTS[0]:SHIP:VELOCITY:ORBIT - SHIP:VELOCITY:ORBIT.
			SET REL_VELOCITY_SHIP	TO (-SHIP:FACING) * REL_VELOCITY.
			SET TGT_ATTITUDE		TO TARGET:FACING.
		}
		
		// ATTITUDE LOCK
		IF HOLD_ATT < 0.5 {
			DISABLE_STEERING().
		}
		IF HOLD_ATT > 0.5 {
			SET CURRENT_STEERING TO ((TGT_ATTITUDE*R(0,0,-DOCK_DR))*R(-DOCK_DP,0,0))*R(0,-DOCK_DY,0).
		}
		
		// POSITION LOCK
		IF HOLD_VEL < 0.5 {
			RESET_RCS().
		}
		IF HOLD_VEL > 0.5 {
			SET SHIP:CONTROL:FORE		TO 1 * (RCS_SENSITIVITY*REL_VELOCITY_SHIP:Z + USER_INPUT_MAG*SHIP:CONTROL:PILOTFORE).
			SET SHIP:CONTROL:STARBOARD	TO 2 * (RCS_SENSITIVITY*REL_VELOCITY_SHIP:X + USER_INPUT_MAG*SHIP:CONTROL:PILOTSTARBOARD).
			SET SHIP:CONTROL:TOP		TO 3 * (RCS_SENSITIVITY*REL_VELOCITY_SHIP:Y + USER_INPUT_MAG*SHIP:CONTROL:PILOTTOP).
		}
	} ELSE {
		DISABLE_STEERING().
		RESET_RCS().
	}
}

FUNCTION MM2_RENDEZVOUS_TASK { PARAMETER DT.
	IF MINOR_MODE = 7 {
		TASK_SCHEDULE(1, MM2_RENDEZVOUS_TASK@).
	} ELSE {
		RETURN.
	}

	IF HASTARGET {
		// ITERATIVELY SEARCH FOR CLOSEST APPROACH
		LOCAL DT0 IS 1.0.
		LOCAL R1 IS (POSITIONAT(SHIP, CLOSEST_APPROACH - DT0) - POSITIONAT(TARGET, CLOSEST_APPROACH - DT0)):MAG.
		LOCAL R2 IS (POSITIONAT(SHIP, CLOSEST_APPROACH + DT0) - POSITIONAT(TARGET, CLOSEST_APPROACH + DT0)):MAG.
		SET DR_DT TO (R1 - R2)/DT0.
		SET CLOSEST_APPROACH TO MAX(TIME:SECONDS, CLOSEST_APPROACH + DR_DT*(APPROACH_SENSITIVITY/100)).
		
		// CALCULATE APPROACH VECTOR
		LOCAL CPOS IS POSITIONAT(SHIP, CLOSEST_APPROACH).
		LOCAL RPOS IS CPOS - POSITIONAT(TARGET, CLOSEST_APPROACH).
		LOCAL NVEC IS (CPOS - SHIP:BODY:POSITION):NORMALIZED.
		LOCAL TVEC IS VELOCITYAT(SHIP, CLOSEST_APPROACH):ORBIT:NORMALIZED.
		LOCAL PVEC IS VCRS(NVEC, TVEC).
		SET APPROACH_VEC TO V(VDOT(RPOS, TVEC), VDOT(RPOS, PVEC), VDOT(RPOS, NVEC)).
		
		// CALCULATE APPROACH PARAMETERS
		SET APPROACH_VEL  TO (VELOCITYAT(SHIP, CLOSEST_APPROACH):ORBIT - VELOCITYAT(TARGET, CLOSEST_APPROACH):ORBIT):MAG.
		SET APPROACH_TIME TO CLOSEST_APPROACH - TIME:SECONDS.
		SET APPROACH_DIST TO RPOS:MAG.
		SET CURRENT_DIST  TO (SHIP:POSITION - TARGET:POSITION):MAG.
	}
}

FUNCTION MM2_TARGET_TRACK_TASK { PARAMETER DT.
	IF MINOR_MODE = 6 {
		TASK_SCHEDULE(1, MM2_TARGET_TRACK_TASK@).
	} ELSE {
		RETURN.
	}

	IF HASTARGET {
		SET REL_POSITION 		TO TARGET:POSITION - SHIP:POSITION.
		SET REL_POSITION_SHIP	TO (-SHIP:FACING) * REL_POSITION.
		SET CURRENT_STEERING	TO ((ANGLEAXIS(0, REL_POSITION)*R(0,0,-DOCK_DR))*R(-DOCK_DP,0,0))*R(0,-DOCK_DY,0).
	}
}

FUNCTION MM2_UI_TASK { PARAMETER DT.
	TASK_SCHEDULE(3, MM2_UI_TASK@).

	IF MINOR_MODE = 2 {
		UI_VARIABLE("    VX",	"M/S",	REL_VELOCITY_SHIP:X,	4,10,SIGNED,	0,3).
		UI_VARIABLE("    VY",	"M/S",	REL_VELOCITY_SHIP:Y,	4,10,SIGNED,	0,4).
		UI_VARIABLE("    VZ",	"M/S",	REL_VELOCITY_SHIP:Z,	4,10,SIGNED,	0,5).

		UI_VARIABLE("     X",	"M",	REL_POSITION_SHIP:X,	4,10,SIGNED,	0,7).
		UI_VARIABLE("     Y",	"M",	REL_POSITION_SHIP:Y,	4,10,SIGNED,	0,8).
		UI_VARIABLE("     Z",	"M",	REL_POSITION_SHIP:Z,	4,10,SIGNED,	0,9).
		                  
		UI_VARIABLE("    dP",	"*",	DOCK_DP,				1,5, SIGNED,	0,11).
		UI_VARIABLE("    dY",	"*",	DOCK_DY,				1,5, SIGNED,	0,12).
		UI_VARIABLE("    dR",	"*",	DOCK_DR,				1,5, SIGNED,	0,13).
		UI_VARIABLE("  PORT",	"",		DOCK_PORT,				0,5, SIGNED,	0,14).
		
		UI_VARIABLE("ATT",		"HOLD",	HOLD_ATT > 0,			0,4, ONOFF,		2,16).
		UI_VARIABLE("VEL",		"HOLD",	HOLD_VEL > 0,			0,4, ONOFF,		16,16).
		
		UI_VARIABLE("RCS[2]",	"",		RCS_SENSITIVITY,		1,5, NUMBER,	16,11).
		UI_VARIABLE("INP[3]",	"",		USER_INPUT_MAG,			1,5, NUMBER,	16,12).
	}
	IF MINOR_MODE = 6 {
		UI_VARIABLE("    X",	"M",	REL_POSITION_SHIP:X,	4,10,SIGNED,	0,3).
		UI_VARIABLE("    Y",	"M",	REL_POSITION_SHIP:Y,	4,10,SIGNED,	0,4).
		UI_VARIABLE("    Z",	"M",	REL_POSITION_SHIP:Z,	4,10,SIGNED,	0,5).

		UI_VARIABLE("   dP",	"*",	DOCK_DP,				1,5, SIGNED,	0,6).
		UI_VARIABLE("   dY",	"*",	DOCK_DY,				1,5, SIGNED,	0,7).
		UI_VARIABLE("   dR",	"*",	DOCK_DR,				1,5, SIGNED,	0,8).
	}
	IF MINOR_MODE = 7 {
		UI_VARIABLE("APP T",	"SEC",	APPROACH_TIME,			1,10,SIGNED,	0,0).		
		UI_VARIABLE("APP D",	"M",	APPROACH_DIST,			1,10,SIGNED,	0,1).
		UI_VARIABLE("CUR A",	"M",	CURRENT_DIST,			1,10,SIGNED,	0,2).
		UI_VARIABLE("APP V",	"M/S",	APPROACH_VEL,			1,10,SIGNED,	0,3).
		
		UI_VARIABLE("   RX",	"M",	APPROACH_VEC:X,			1,10,SIGNED,	0,4).
		UI_VARIABLE("   RY",	"M",	APPROACH_VEC:Y,			1,10,SIGNED,	0,5).
		UI_VARIABLE("   RZ",	"M",	APPROACH_VEC:Z,			1,10,SIGNED,	0,6).
		
		UI_VARIABLE("   DT",	"M/S",	DR_DT,					2,10,SIGNED,	0,8).
		
		UI_VARIABLE("SNS[1]",	"",		APPROACH_SENSITIVITY,	1,5,NUMBER,		0,10).
	}
}.

FUNCTION MM2_COMMAND {
	PARAMETER VERB, VALUE.

	IF VERB = 1 {
		IF MINOR_MODE = 7 {
			// V1 SET APPROACH NUMERICAL SENSITIVITY
			SET APPROACH_SENSITIVITY TO VALUE.
			SET_PVAR("APP_SENS", VALUE).
		} ELSE IF MINOR_MODE = 2 { 
			// V1 SET DOCKING PORT
			SET DOCK_PORT TO VALUE.
			SET_PVAR("PORT", VALUE).
		}
	}
	IF VERB = 2 {
		IF MINOR_MODE = 7 { 
			// V2 RESET APPROACH GUIDANCE
			IF HASTARGET {
				IF VALUE = 0 {
					SET CLOSEST_APPROACH TO TIME:SECONDS + 10.
				} ELSE IF VALUE = 1 {
					SET CLOSEST_APPROACH TO TIME:SECONDS + 1 * MAX(SHIP:OBT:PERIOD, TARGET:OBT:PERIOD).
				} ELSE IF VALUE = 2 {
					SET CLOSEST_APPROACH TO TIME:SECONDS + 2 * MAX(SHIP:OBT:PERIOD, TARGET:OBT:PERIOD).
				}
			} ELSE {
				SET CLOSEST_APPROACH TO TIME:SECONDS.
			}
		} ELSE IF MINOR_MODE = 2 { 
			// V2 SET RCS SENSITIVITY
			SET RCS_SENSITIVITY TO VALUE.
			SET_PVAR("RCS_SENS", VALUE).
		}
	}
	IF VERB = 3 { // SET USER INPUT MAG
		IF MINOR_MODE = 2 { 
			SET USER_INPUT_MAG TO VALUE.
			SET_PVAR("UI_MAG", VALUE).
		}
	}
	IF VERB = 4 { // SET DELTA X
		SET DOCK_DP TO VALUE.
		SET_PVAR("DP", VALUE).
	}
	IF VERB = 5 { // SET DELTA Y
		SET DOCK_DY TO VALUE.
		SET_PVAR("DY", VALUE).
	}
	IF VERB = 6 { // SET DELTA Z
		SET DOCK_DR TO VALUE.
		SET_PVAR("DZ", VALUE).
	}
	IF VERB = 7 { // ATT HOLD
		IF MINOR_MODE = 2 { 
			SET HOLD_ATT TO VALUE.
			SET_PVAR("HOLD_ATT", VALUE).
			IF VALUE > 0.5 {
				ENABLE_STEERING().
				SAS OFF.
			}
		}
	}
	IF VERB = 8 { // VEL HOLD
		IF MINOR_MODE = 2 { 
			SET HOLD_VEL TO VALUE.
			SET_PVAR("HOLD_VEL", VALUE).
		}
	}
	IF VERB = 9 {
		FOR MODULE IN SHIP:MODULESNAMED("KASModuleHarpoon") {
			MODULE:DOACTION("DETACH", TRUE ).
		}
	}
}




////////////////////////////////////////////////////////////////////////////////
MODE_NAMES:ADD(20, "ORBIT MONITOR   ").
MODE_NAMES:ADD(21, "LOW-POWER MODE  ").
MODE_NAMES:ADD(22, "STATION KEEPING ").
MODE_NAMES:ADD(26, "TARGET TRACKING ").
MODE_NAMES:ADD(27, "RENDEZVOUS APPCH").

MODE_ENTER		(2, MM2_ENTER@).
MODE_TRANSFER	(2, MM2_TRANSFER@).
MODE_LEAVE		(2, MM2_LEAVE@).
MODE_COMMAND	(2, MM2_COMMAND@).

MODE_TASK		(2, MM2_UI_TASK@).
