////////////////////////////////////////////////////////////////////////////////
//	LNDR		LANDER VEHICLE FIRMWARE
////////////////////////////////////////////////////////////////////////////////
// LOAD OPERATING SYSTEM
RUN RTSK.


////////////////////////////////////////////////////////////////////////////////
// MM1			LANDING
////////////////////////////////////////////////////////////////////////////////
FUNCTION MM1_ENTER {
	GLOBAL TARGET TO LATLNG(0.0, 0.0).

}

FUNCTION MM1_LEAVE {
	DISABLE_STEERING().
}

FUNCTION MM1_TRANSFER {
	IF MINOR_MODE = 0 {
		ENABLE_STEERING().
	}
	IF MINOR_MODE = 1 {
		DISABLE_STEERING().
	}
}

FUNCTION MM3_COMMAND {
	PARAMETER VERB, VALUE.
	// NOTHING
}

FUNCTION MM1_GUIDANCE_TASK { PARAMETER DT.
	TASK_SCHEDULE(1, MM1_GUIDANCE_TASK@).
}

FUNCTION MM1_UI_TASK { PARAMETER DT.
	//UI_VARIABLE("RADALT",	"M",	ALT:RADAR, 								0,7, NUMBER,	0,0).
	
	TASK_SCHEDULE(3, MM1_UI_TASK@).
}


////////////////////////////////////////////////////////////////////////////////
MODE_NAMES:ADD(30, "FLIGHT MONITOR  ").
MODE_ENTER		(3, MM1_ENTER@).
MODE_TRANSFER	(3, MM1_TRANSFER@).
MODE_LEAVE		(3, MM1_LEAVE@).
MODE_COMMAND	(3, MM1_COMMAND@).
MODE_TASK		(3, MM1_GUIDANCE_TASK@).
MODE_TASK		(3, MM1_UI_TASK@).


////////////////////////////////////////////////////////////////////////////////
// LOAD FLIGHT SOFTWARE
RUN OV_MM2.
	
// ADD MADS TASK
TASK_MADS(INIT).

// START THE OPERATING SYSTEM
ENTRYPOINT().