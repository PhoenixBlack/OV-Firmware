////////////////////////////////////////////////////////////////////////////////
// MAJOR MODE 2 (ON-ORBIT)
////////////////////////////////////////////////////////////////////////////////
FUNCTION MAJOR_MODE2_TRANSFER {
	// ..
}

FUNCTION MAJOR_MODE2 {
	IF MINOR_MODE = 0 { // MONITOR
		RCS OFF.
	}
	IF MINOR_MODE = 1 {	// LOW-POWER MODE
		WAIT 1.0.
		RETURN.
	}
	
	// DISPLAY OUTPUT
	IF UI_UPDATE {
		PRINT_VAR(0, "ALT",	"M",	7, ROUND(ALTITUDE/10,0)*10,			0,0).
		PRINT_VAR(1, "APO",	"M",	7, ROUND(SHIP:APOAPSIS/10,0)*10,	0,1).
		PRINT_VAR(2, "PER",	"M",	7, ROUND(SHIP:PERIAPSIS/10,0)*10,	0,2).
	}
}