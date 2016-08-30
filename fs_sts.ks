////////////////////////////////////////////////////////////////////////////////
// CONSTANTS AND INCLUDES
////////////////////////////////////////////////////////////////////////////////
//
// SHUTTLE DATA
//
//
// OV-099
//	DRY MASS:			16,944 kg
//
//
// OV-101	
//			DRY MASS	ASC MASS	RET MASS	CS RESIDUAL
//	STS-1	18,752 kg	28,388 kg	26,026 kg
//	STS-2	18,752 kg	33,513 kg	20,775 kg
//	STS-3	18,752 kg	34,514 kg	23,780 kg
//	STS-4	18,752 kg	33,364 kg	21,524 kg
//	STS-5	18,752 kg	34,339 kg	22,400 kg
//	STS-6	18,752 kg	37,469 kg	23,108 kg	
//
//	DRY MASS:	18,752 kg
//	MAX MASS:	38,100 kg (launch)		32,704 kg (return)
//	MAX PAYLOD:	19,348 kg (launch)		13,952 kg (return)
//
//	MAX G:		-2.0 .. 4.0 g
//	MAX Q:		21.0 kPA
//	MAX ALPHA:	43.0 DEG
//	MIN ALPHA:	25.0 DEG	(M < 4.25)
//				32.5 DEG	(M > 4.75)
//
//	ENTRY ENVELOPE:
//		NORMAL CG:		7.509 .. 7.723 m
//		HI-HEAT CG:		7.509 .. 7.770 m	(possible extra thermal load on bodyflap)
//		STABILITY CG:	7.264 .. 7.846 m
//		RCS:			125u				(no less than)
//
//	NO-PAYLOAD RESTRICTION:
//		FUEL:	112u	560kg	(no less than)
//		OXY:	137u	680kg	(no less than)
//
//	ENTRY RESIDUALS
//				dV 			dZ
//		STS-1	+246 m/s	+2186 m
//		STS-2	+112 m/s	+996 m
//		STS-3	+114 m/s	+1212 m
//		STS-4	+134 m/s	+1921 m
//		STS-5	+105 m/s	+933 m
//		STS-6	+120 m/s	+231 m
//
//
// ENTRY CENTER OF MASS BALLANCE:
//	CM (m)	BODYFLAP (deg)
//	7.846	110		(-0.5 pitch)
//	7.809	110
//	7.781	108
//	7.770	105
//	7.758	100
//	7.748	95
//	7.723	90
//	7.667	85
//	7.607	80
//	7.509	70
//	7.264	70		(+0.5 pitch)
//
// BODY FLAP POSITION EQUATIONS
//	BODYFLAP =  -677.79 +  99.57*CM			CM: [7.509 .. 7.748]	(NORMAL RANGE)
//	BODYFLAP = -2967.82 + 395.62*CM			CM: [7.748 .. 7.781]	(EXTENDED RANGE)
//
////////////////////////////////////////////////////////////////////////////////
// MAJOR MODE 1
SET MM1_FULL_THRUST		TO 4700.	// FULL THRUST OF STACK (BEFORE BOOSTER SEP)
SET MM1_STEERING_ANGLE	TO 45.		// ENTRY ANGLE FOR CLOSED LOOP TRAJECTORY PORTION
SET MM1_CUTOFF_ANGLE	TO -20.		// NOMINAL CUTOFF ANGLE TO AIM FOR
SET MM1_MIN_ANGLE		TO -50.		// MIN ALLOWED ANGLE DURING CLOSED LOOP PORTION
SET MM1_CUTOFF_PER		TO -50000.	// CUTOFF PERIAPSIS

// MAJOR MODE 3
SET MM3_TARGET_SPEED	TO 115.		// NOMINAL PRE-LANDING SPEED
SET MM3_GLIDE_ALT		TO 5.		// ALTITUDE OF TRANSITION TO 1 M/S GLIDE
SET MM3_GLIDE_ANG		TO 15.  	// GLIDESLOPE ANGLE
SET MM3_FLARE_ALT		TO 400. 	// ALTITUDE OF FLARE
SET MM3_H1_PARAM		TO 100. 	// HIGHER NUMBER = SHARPER FLARE
SET MM3_FINAL_ALT		TO 80.		// FINAL FLARE ALTITUDE
SET RUNWAY				TO LATLNG(-0.0486, -74.6848 - 0.10). //74.4970 other end

// MAJOR MODE 6
SET MM6_BURN_DISTANCE	TO 1050000.	// REENTRY BURN DISTANCE
SET MM6_ROLL_REV_SPEED	TO 8.		// MAXIMUM ROLL COMMAND SPEED (DEG/SEC)
SET MM6_BASE_AOA		TO 35.		// BASE ANGLE OF ATTACK
SET MM6_TARGET_DISTANCE	TO 110000.	// TARGET POINT DISTANCE
SET MM6_TARGET_ALT		TO 28000.	// TARGET POINT ALTITUDE	(EST RESIDUAL < 2000 M)
SET MM6_TARGET_SPEED	TO 800.		// TARGET VELOCITY			(EST RESIDUAL < 150 M/S)




////////////////////////////////////////////////////////////////////////////////
// LOAD SOFTWARE
////////////////////////////////////////////////////////////////////////////////
RUN SYS.
RUN EVENT.

// LOAD MAJOR MODES
RUN MM1.
RUN MM2.
RUN MM3.
RUN MM5.
RUN MM6.

// LOAD FLIGHT SOFTWARE
RUN FS.