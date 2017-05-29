////////////////////////////////////////////////////////////////////////////////
// RTSK		STEERING INTERFACE
////////////////////////////////////////////////////////////////////////////////
// CURRENTLY USED STEERING VALUE
GLOBAL CURRENT_STEERING TO HEADING(0,0).
// CURRENTLY USED THROTTLE VALUE
GLOBAL CURRENT_THROTTLE TO 0.

// IS COMPUTER CONNECTED TO PHYSICAL OUTPUTS
GLOBAL OUTPUT_PERMITTED TO TRUE.

// CHANGE STATE OF OUTPUT PERMISSION
ON OUTPUT_PERMITTED {
	IF NOT OUTPUT_PERMITTED {
		DISABLE_STEERING().
		DISABLE_RCS_TRANSLATION().
		DISABLE_RCS().
	}
	PRESERVE.
}


////////////////////////////////////////////////////////////////////////////////
// ENABLE STEERING
FUNCTION ENABLE_STEERING {
	IF OUTPUT_PERMITTED {
		LOCK STEERING TO CURRENT_STEERING.
	} ELSE {
		DISABLE_STEERING().
	}
}

// DISABLE STEERING
FUNCTION DISABLE_STEERING {
	UNLOCK STEERING.
	SET SHIP:CONTROL:PITCH TO 0.0.
	SET SHIP:CONTROL:YAW TO 0.0.
	SET SHIP:CONTROL:ROLL TO 0.0.
	SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
}


////////////////////////////////////////////////////////////////////////////////
// ENABLE THROTTLE
FUNCTION ENABLE_THROTTLE {
	IF OUTPUT_PERMITTED {
		LOCK THROTTLE TO MIN(SHIP:CONTROL:PILOTMAINTHROTTLE, CURRENT_THROTTLE).
	} ELSE {
		DISABLE_THROTTLE().
	}
}

// DISABLE STEERING
FUNCTION DISABLE_THROTTLE {
	UNLOCK THROTTLE.
	SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
	SET CURRENT_THROTTLE TO 0.
}


////////////////////////////////////////////////////////////////////////////////
// ENABLE RCS
FUNCTION ENABLE_RCS {
	IF OUTPUT_PERMITTED {
		RCS ON.
	} ELSE {
		DISABLE_RCS().
	}
}

// DISABLE STEERING
FUNCTION DISABLE_RCS {
	RCS OFF.
	SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
	SET SHIP:CONTROL:FORE		TO 0.
	SET SHIP:CONTROL:STARBOARD	TO 0. 
	SET SHIP:CONTROL:TOP		TO 0.
}

// DISABLE STEERING
FUNCTION RESET_RCS {
	SET SHIP:CONTROL:NEUTRALIZE TO TRUE.
	SET SHIP:CONTROL:FORE		TO 0.
	SET SHIP:CONTROL:STARBOARD	TO 0. 
	SET SHIP:CONTROL:TOP		TO 0.
}




////////////////////////////////////////////////////////////////////////////////
FUNCTION SERVO_GET {
	PARAMETER NAME.
	FOR SERVO IN ADDONS:IR:ALLSERVOS {
		IF SERVO:NAME = NAME {
			RETURN SERVO:POSITION.
		}
	}
	RETURN 0.
}

FUNCTION SERVO_SET {
	PARAMETER NAME, VALUE, SPEED.
	FOR SERVO IN ADDONS:IR:ALLSERVOS {
		IF SERVO:NAME = NAME {
			SERVO:MOVETO(VALUE, SPEED).
			BREAK.
		}
	}
}