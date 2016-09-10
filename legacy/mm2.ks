////////////////////////////////////////////////////////////////////////////////
// MAJOR MODE 2 (ON-ORBIT)
////////////////////////////////////////////////////////////////////////////////
FUNCTION MAJOR_MODE2_TRANSFER {
	// RESET PARAMETERS
	IF RESTART OR (MINOR_MODE = 0) {
		SET MM2_DOCK_DP TO 0.
		SET MM2_DOCK_DY TO 0.
		SET MM2_DOCK_DR TO 0.		
		SET MM2_DOCK_PORT TO 0.
		SET MM2_RCS_SENSITIVITY TO 10.
		SET MM2_USER_INPUT_MAG TO 2.
		
		SET MM2_TARGET_ALT TO 130000.
		
		SET MM2_APPROACH_SENSITIVITY TO 50.
	}
	
	// UNLOCK CONTROLS
	UNLOCK THROTTLE.
	UNLOCK STEERING.
	SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
	SET SHIP:CONTROL:FORE		TO 0.
	SET SHIP:CONTROL:STARBOARD	TO 0.
	SET SHIP:CONTROL:TOP		TO 0.

	// RESET APPROACH GUIDANCE
	SET CLOSEST_APPROACH TO TIME:SECONDS.
	//IF MINOR_MODE = 7 {
		//MAJOR_MODE2_COMMAND(2,0).
	//}
}

FUNCTION MAJOR_MODE2_COMMAND {
	PARAMETER CMD.
	PARAMETER VALUE.
	
	IF CMD = 1 { // VERB 1
		IF MINOR_MODE = 7 { // SET APPROACH NUMERICAL SENSITIVITY
			SET MM2_APPROACH_SENSITIVITY TO VALUE.
		} ELSE { // SET DOCKING PORT
			SET MM2_DOCK_PORT TO VALUE.
		}
	}
	IF CMD = 2 { // VERB 2
		IF MINOR_MODE = 7 { // RESET APPROACH GUIDANCE
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
		} ELSE {// SET RCS SENSITIVITY
			SET MM2_RCS_SENSITIVITY TO VALUE.
		}
	}
	IF CMD = 3 { // VERB 3: SET USER INPUT MAG
		SET MM2_USER_INPUT_MAG TO VALUE.
	}
	IF CMD = 4 { // VERB 4: SET DELTA X
		SET MM2_DOCK_DP TO VALUE.
	}
	IF CMD = 5 { // VERB 5: SET DELTA Y
		SET MM2_DOCK_DY TO VALUE.
	}
	IF CMD = 6 { // VERB 6: SET DELTA Z
		SET MM2_DOCK_DR TO VALUE.
	}
}

FUNCTION MAJOR_MODE2 {
	IF MINOR_MODE = 0 { // MONITOR
		UNLOCK STEERING.
	}
	IF MINOR_MODE = 1 {	// LOW-POWER MODE
		UNLOCK STEERING.
		WAIT 1.0.
		RETURN.
	}
	IF (MINOR_MODE = 2) OR
	   (MINOR_MODE = 3) OR 
	   (MINOR_MODE = 4) OR 
	   (MINOR_MODE = 5) { // STATION-KEEPING/DOCKING

		IF HASTARGET {
			// FIND DOCKING PORT, IF SELECTED
			SET PORTS TO TARGET:PARTSTAGGED("DOCK" + MM2_DOCK_PORT).		
		
			// RELATIVE POSITION/VELOCITY
			IF (MM2_DOCK_PORT = 0) OR (PORTS:LENGTH = 0) {
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
			IF (MINOR_MODE = 2) OR (MINOR_MODE = 5) {
				UNLOCK STEERING.
				SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
			}
			IF (MINOR_MODE = 3) OR (MINOR_MODE = 4) {
				SET TARGET_DIR TO TGT_ATTITUDE.
				LOCK STEERING TO ((TGT_ATTITUDE*R(0,0,-MM2_DOCK_DR))*R(-MM2_DOCK_DP,0,0))*R(0,-MM2_DOCK_DY,0).
			}
			
			// POSITION LOCK
			IF (MINOR_MODE = 2) OR (MINOR_MODE = 3) {
				SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
			}
			IF (MINOR_MODE = 4) OR (MINOR_MODE = 5) {
				SET SHIP:CONTROL:FORE		TO 1 * (MM2_RCS_SENSITIVITY * REL_VELOCITY_SHIP:Z + MM2_USER_INPUT_MAG*SHIP:CONTROL:PILOTFORE).
				SET SHIP:CONTROL:STARBOARD	TO 2 * (MM2_RCS_SENSITIVITY * REL_VELOCITY_SHIP:X + MM2_USER_INPUT_MAG*SHIP:CONTROL:PILOTSTARBOARD).
				SET SHIP:CONTROL:TOP		TO 3 * (MM2_RCS_SENSITIVITY * REL_VELOCITY_SHIP:Y + MM2_USER_INPUT_MAG*SHIP:CONTROL:PILOTTOP).
			}
		} ELSE {
			SET REL_POSITION		TO V(0,0,0).
			SET REL_POSITION_SHIP	TO V(0,0,0).
			SET REL_VELOCITY		TO V(0,0,0).
			SET REL_VELOCITY_SHIP	TO V(0,0,0).
				
			UNLOCK STEERING.
			SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
		}
	}
	IF MINOR_MODE = 6 {	// TARGET TRACKING
		IF HASTARGET {
			SET REL_POSITION 		TO TARGET:POSITION - SHIP:POSITION.
			SET REL_POSITION_SHIP	TO (-SHIP:FACING) * REL_POSITION.
			LOCK STEERING TO ((ANGLEAXIS(0, REL_POSITION)*R(0,0,-MM2_DOCK_DR))*R(-MM2_DOCK_DP,0,0))*R(0,-MM2_DOCK_DY,0).
		} ELSE {
			SET REL_POSITION 		TO V(0,0,0).
			SET REL_POSITION_SHIP	TO V(0,0,0).
			UNLOCK STEERING.
			SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
		}
	}
	IF MINOR_MODE = 7 {	// ORBITAL MANEUVERING
		IF HASTARGET {
			// ITERATIVELY SEARCH FOR CLOSEST APPROACH
			SET DR_DT TO ESTIMATE_DERIVATIVE(SHIP, TARGET, CLOSEST_APPROACH, 1.0).
			SET CLOSEST_APPROACH TO MAX(TIME:SECONDS, CLOSEST_APPROACH + DR_DT*(MM2_APPROACH_SENSITIVITY/100)).
			
			// CALCULATE APPROACH VECTOR
			SET CPOS TO POSITIONAT(SHIP, CLOSEST_APPROACH).
			SET RPOS TO CPOS - POSITIONAT(TARGET, CLOSEST_APPROACH).
			SET NVEC TO (CPOS - SHIP:BODY:POSITION):NORMALIZED.
			SET TVEC TO VELOCITYAT(SHIP, CLOSEST_APPROACH):ORBIT:NORMALIZED.
			SET PVEC TO VCRS(NVEC, TVEC).
			SET APPROACH_VEC TO V(VDOT(RPOS, TVEC), VDOT(RPOS, PVEC), VDOT(RPOS, NVEC)).
			
			// CALCULATE APPROACH PARAMETERS
			SET APPROACH_VEL  TO (VELOCITYAT(SHIP, CLOSEST_APPROACH):ORBIT - VELOCITYAT(TARGET, CLOSEST_APPROACH):ORBIT):MAG.
			SET APPROACH_TIME TO CLOSEST_APPROACH - TIME:SECONDS.
			SET APPROACH_DIST TO RPOS:MAG.
			SET CURRENT_DIST  TO (SHIP:POSITION - TARGET:POSITION):MAG.
		} ELSE {
			SET DR_DT TO 0.
			SET APPROACH_TIME TO 0.
			SET APPROACH_VEC  TO V(0,0,0).
			SET APPROACH_VEL  TO 0.
			SET APPROACH_DIST TO 0.
			SET CURRENT_DIST  TO 0.
		}
	}

	// DISPLAY OUTPUT
	IF UI_UPDATE {
		PRINT_VAR(0, " H",	"M",	6, ROUND(ALTITUDE/10,0)*10,			0,0).
		PRINT_VAR(1, "AP",	"M",	6, ROUND(SHIP:APOAPSIS/10,0)*10,	13,0).
		PRINT_VAR(2, "PE",	"M",	6, ROUND(SHIP:PERIAPSIS/10,0)*10,	13,1).
		PRINT_VAR(3, "RF",	"U",	6, ROUND(RCSF+RCSL+RCSR,2),			0,1).
		
		IF (MINOR_MODE = 2) OR 
		   (MINOR_MODE = 3) OR 
		   (MINOR_MODE = 4) OR 
		   (MINOR_MODE = 5) {
			PRINT_VAR(4, "+VX",	"M/S",	7, ROUND(REL_VELOCITY_SHIP:X,4),	0,3).
			PRINT_VAR(5, "+VY",	"M/S",	7, ROUND(REL_VELOCITY_SHIP:Y,4),	0,4).
			PRINT_VAR(6, "+VZ",	"M/S",	7, ROUND(REL_VELOCITY_SHIP:Z,4),	0,5).
			
			PRINT_VAR(7, " +X",	"M",	7, ROUND(REL_POSITION_SHIP:X,2),	0,6).
			PRINT_VAR(8, " +Y",	"M",	7, ROUND(REL_POSITION_SHIP:Y,2),	0,7).
			PRINT_VAR(9, " +Z",	"M",	7, ROUND(REL_POSITION_SHIP:Z,2),	0,8).
			
			PRINT_VAR(10, "dP",	"*",	4, ROUND(MM2_DOCK_DP,0),			14,6).
			PRINT_VAR(11,"dY",	"*",	4, ROUND(MM2_DOCK_DY,0),			14,7).
			PRINT_VAR(12,"dR",	"*",	4, ROUND(MM2_DOCK_DR,0),			14,8).
			PRINT_VAR(13,"PORT","",		1, MM2_DOCK_PORT,					14,9).
		}
		IF MINOR_MODE = 6 {
			PRINT_VAR(4, " +X",	"M",	7, ROUND(REL_POSITION_SHIP:X,0),	0,3).
			PRINT_VAR(5, " +Y",	"M",	7, ROUND(REL_POSITION_SHIP:Y,0),	0,4).
			PRINT_VAR(6, " +Z",	"M",	7, ROUND(REL_POSITION_SHIP:Z,0),	0,5).
			
			PRINT_VAR(7, "dP",	"*",	4, ROUND(MM2_DOCK_DP,0),			14,3).
			PRINT_VAR(8, "dY",	"*",	4, ROUND(MM2_DOCK_DY,0),			14,4).
			PRINT_VAR(9, "dR",	"*",	4, ROUND(MM2_DOCK_DR,0),			14,5).
		}
		IF MINOR_MODE = 7 {
			PRINT_VAR(4, "DT",	"M/S",	6, ROUND(MIN(999,DR_DT),1),				0,3).
			PRINT_VAR(5, "-T",	"SEC",	6, ROUND(MIN(999999,APPROACH_TIME),0),	0,4).
			PRINT_VAR(6, "-D",	"M",	6, ROUND(MIN(999999,APPROACH_DIST),0),	0,5).
			PRINT_VAR(7, "+D",	"M",	6, ROUND(MIN(999999,CURRENT_DIST),0),	13,5).
			PRINT_VAR(8, "+V",	"M/S",	3, ROUND(MIN(999,APPROACH_VEL),0),		13,7).
			PRINT_VAR(9, "+X",	"M",	7, ROUND(APPROACH_VEC:X,0),				0,7).
			PRINT_VAR(10,"+Y",	"M",	7, ROUND(APPROACH_VEC:Y,0),				0,8).
			PRINT_VAR(11,"+Z",	"M",	7, ROUND(APPROACH_VEC:Z,0),				0,9).
		}
	}
}


FUNCTION ESTIMATE_DERIVATIVE {
	PARAMETER SHIP1.
	PARAMETER SHIP2.
	PARAMETER T.
	PARAMETER DT.
	
	LOCAL R1 IS (POSITIONAT(SHIP1, T - DT) - POSITIONAT(SHIP2, T - DT)):MAG.
	LOCAL R2 IS (POSITIONAT(SHIP1, T + DT) - POSITIONAT(SHIP2, T + DT)):MAG.
	RETURN (R1 - R2)/DT.
}