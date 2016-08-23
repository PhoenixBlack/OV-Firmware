////////////////////////////////////////////////////////////////////////////////
// CONSTANTS AND INCLUDES
////////////////////////////////////////////////////////////////////////////////
//
// SHUTTLE DATA
//
// OV-101
//				[DRY MASS]	[ASC MAX]	[RET MAX]	[ASC LOAD]	[LAND LOAD]	ASC MASS	RET MASS
//	Ground test	18,704 kg	32,704 kg	32,704 kg	14,000 kg	14,000 kg	--,--- kg	--,--- kg
//	STS-1		18,752 kg	32,704 kg	32,704 kg	14,000 kg	13,952 kg	28,388 kg	26,026 kg
//	STS-2		18,752 kg	34,000 kg	32,704 kg	15,248 kg	13,952 kg	33,443 kg	--,--- kg
//
//	DRY MASS:			18,752 kg
//	MAX LAUNCH MASS:	34,000 kg
//	MAX LAND MASS:		32,704 kg
//	MAX LAUNCH PAYLOD:	15,248 kg
//	MAX LAND PAYLOAD:	13,952 kg
//
//	MAX G:		-2.0 .. 4.0 g
//	MAX Q:		21.0 kPA
//	MAX ALPHA:	43.0 DEG
//	MIN ALPHA:	25.0 DEG	(M < 4.25)
//				32.5 DEG	(M > 4.75)
//
//	NORMAL ENTRY CG:			7.509 .. 7.723 m
//	HI BODYFLAP HEAT ENTRY CG:	7.509 .. 7.770 m
//	MAX STABILITY CG RANGE:		7.264 .. 7.846 m
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
SET MM1_STEERING_ANGLE	TO 55.		// ENTRY ANGLE FOR CLOSED LOOP TRAJECTORY PORTION
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
SET RUNWAY				TO LATLNG(-0.0486, -74.6848 - 0.07). //74.4970 other end

// MAJOR MODE 6
//SET MM6_BASE_AOA		TO 35.		// BASE ANGLE OF ATTACK
SET MM6_BASE_AOA		TO 25.		// BASE ANGLE OF ATTACK

SET MM6_TARGET_ALT		TO 28000.	// TARGET POINT ALTITUDE	+-  2000 M
SET MM6_TARGET_DISTANCE	TO 110000.	// TARGET POINT DISTANCE	+- 10000 M
SET MM6_TARGET_SPEED	TO 800.		// TARGET VELOCITY			+-   200 M/S
SET MM6_BURN_DISTANCE	TO 1050000.	// REENTRY BURN DISTANCE




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