////////////////////////////////////////////////////////////////////////////////
// RTSK		SYSTEMS DIAGNOSTICS
////////////////////////////////////////////////////////////////////////////////

FUNCTION MM9_ENTER {
	// NOTHING
}

FUNCTION MM9_LEAVE {
	// NOTHING
}

FUNCTION MM9_TRANSFER {
	// NOTHING
}

FUNCTION MM9_COMMAND {
	PARAMETER VERB, VALUE.
	
	IF VERB = 1 { // RESET EVENTS
		LOCAL I IS 0.
		UNTIL I = NUM_EVENTS {
			SET EVENTS[I][0] TO "".
			SET EVENTS[I][1] TO LOW.
			SET EVENTS[I][2] TO 0.			
			SET I TO I + 1.
		}
	}
}

FUNCTION MM9_SHOW_EVENTS { PARAMETER DT.
	LOCAL I IS 0.
	UNTIL I = NUM_EVENTS {
		LOCAL PRIO IS "LO".
		IF EVENTS[I][1] = HIGH { SET PRIO TO "HI". }
		
		// DRAW EVENT LIST
		UI_VARIABLE("EVT"+I, "", (FORMAT_TIME(EVENTS[I][2]) + " " + PRIO + " " + EVENTS[I][0]):PADRIGHT(24), 0,24, TEXT, 0,I).
		SET I TO I + 1.
	}
	
	TASK_SCHEDULE(5, MM9_SHOW_EVENTS@).
}


////////////////////////////////////////////////////////////////////////////////
// MAJOR MODE 9
////////////////////////////////////////////////////////////////////////////////
MODE_NAMES:ADD(90, "EVENT HISTORY   ").
MODE_NAMES:ADD(91, "SYS DIAGNOSTICS ").

MODE_ENTER		(9, MM9_ENTER@).
MODE_TRANSFER	(9, MM9_TRANSFER@).
MODE_COMMAND	(9, MM9_COMMAND@).
MODE_TASK		(9, MM9_SHOW_EVENTS@). 
MODE_LEAVE		(9, MM9_LEAVE@).