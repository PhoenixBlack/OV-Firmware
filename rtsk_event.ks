////////////////////////////////////////////////////////////////////////////////
// RTSK		EVENT SUBSYSTEM
////////////////////////////////////////////////////////////////////////////////
// IS THERE A PENDING EVENT THAT SHOULD BE ACCEPTED
GLOBAL EVENT_PENDING TO FALSE.

// NUMBER OF EVENTS TRACKED
GLOBAL NUM_EVENTS TO 10.

// EVENT PRIORITIES
GLOBAL  LOW TO 0.
GLOBAL HIGH TO 1.

// TRIGGERS STATE
GLOBAL TRIGGERS TO LEXICON().

//
// EVENT HISTORY
//	EVENT[0] CODE
//	EVENT[1] PRIORITY
//	EVENT[2] TIME
//
GLOBAL EVENTS TO LIST().
LOCAL I TO 0.
UNTIL I = 10 {
	EVENTS:ADD(LIST("", LOW, 0)).
	SET I TO I + 1.
}




////////////////////////////////////////////////////////////////////////////////
//
// LOAD EVENTS TASK
//
FUNCTION TASK_LOADEVENTS { PARAMETER DT.
	LOCAL I TO 0.
	UNTIL I = NUM_EVENTS {
		SET EVENTS[I][0] TO GET_PVAR("$EVENT[" + I + "][0]", "").
		SET EVENTS[I][1] TO GET_PVAR( "EVENT[" + I + "][1]", LOW).
		SET EVENTS[I][2] TO GET_PVAR( "EVENT[" + I + "][2]", 0).
		SET I TO I + 1.
	}
}
TASK_SCHEDULE(4, TASK_LOADEVENTS@).


//
// SAVE EVENTS TASK
//
FUNCTION TASK_SAVEEVENTS { PARAMETER DT.
	LOCAL I TO 0.
	UNTIL I = NUM_EVENTS {
		SET_PVAR_FAST("$EVENT[" + I + "][0]", EVENTS[I][0]).
		SET_PVAR_FAST( "EVENT[" + I + "][1]", EVENTS[I][1]).
		SET_PVAR_FAST( "EVENT[" + I + "][2]", ROUND(EVENTS[I][2],3)).
		SET I TO I + 1.
	}
	TASK_SCHEDULE(6, TASK_PVAR_SAVE@).
}




////////////////////////////////////////////////////////////////////////////////
// PUSH A SINGLE EVENT ON EVENT QUEUE
FUNCTION PUSH_EVENT {
	PARAMETER CODE.
	PARAMETER PRIORITY.
	
	// SHIFT EVENT HISTORY
	LOCAL I TO NUM_EVENTS-1.
	UNTIL I = 0 {
		SET EVENTS[I] TO EVENTS[I-1].
		SET I TO I - 1.
	}
	
	// WRITE EVENT
	SET EVENTS[0] TO LIST(CODE:PADRIGHT(12):SUBSTRING(0,12), PRIORITY, MISSIONTIME).
	
	// RAISE EVENT
	IF PRIORITY = HIGH {
		SET EVENT_PENDING TO TRUE.
		EVENT_REDRAW().
	}
	
	// SCHEDULE EVENTS LOG TO BE SAVED
	TASK_SCHEDULE(6, TASK_SAVEEVENTS@).
}.

// PUSHES AN EVENT WHEN TRIGGER IS TRUE
FUNCTION TRIGGER_CHECK {
	PARAMETER CODE, PRIORITY, VALUE.
	
	IF NOT TRIGGERS:HASKEY(CODE) {
		TRIGGERS:ADD(CODE, FALSE).
	}
	
	IF (VALUE >= 1.0) AND (NOT TRIGGERS[CODE]) {
		PUSH_EVENT("T" + CODE, PRIORITY).
		SET TRIGGERS[CODE] TO TRUE.
	} ELSE IF (VALUE <= -1.0) AND TRIGGERS[CODE] {
		PUSH_EVENT("R" + CODE, LOW).
		SET TRIGGERS[CODE] TO FALSE.
	}
}




////////////////////////////////////////////////////////////////////////////////
// SHOW EVENT LINE
FUNCTION EVENT_REDRAW {
	CLEARLINE(1).
	
	// DRAW PENDING EVENT
	IF EVENT_PENDING {
		PRINT "E" + FORMAT_TIME(EVENTS[0][2]) AT (0,1).
		PRINT EVENTS[0][0] AT (10+13*0,1).
		PRINT EVENTS[1][0] AT (10+13*1,1).
		PRINT EVENTS[2][0] AT (10+13*2,1).
	}

	// IF LOOKING AT EVENTS LIST, REDRAW IT AS WELL
	//IF SYSTEM_SCREEN = 1 {
	//	IF NOT UI_SYSTEMS_SCREENS_REFRESH {
	//		SET UI_SYSTEMS_SCREENS_REFRESH TO TRUE.
	//		TASK_SCHEDULE(0, TASK_UI_SYSTEMS_SCREENS@).
	//	}
	//}
}