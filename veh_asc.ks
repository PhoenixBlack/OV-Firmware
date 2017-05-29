////////////////////////////////////////////////////////////////////////////////
//	VEH		ASCENT VEHICLE FIRMWARE
////////////////////////////////////////////////////////////////////////////////
// LOAD OPERATING SYSTEM
RUN RTSK.

///////////////////////////// MAJOR MODE 4 /////////////////////////////////////
//	NUMBER OF STAGES (1: SINGLE STAGE, 2: TWO-STAGE)
GLOBAL MM4_NUMBER_OF_STAGES		TO 2.
//	WHICH STAGE NUMBER IS THE FIRST STAGE. GUIDANCE WILL HOLD OPEN LOOP UNTIL
//	THIS STAGE.
GLOBAL MM4_FIRST_STAGE_NO		TO 3.

//	STAGE[1]: CONSTANT ACCELERATION (LEAVE 0 IF CONSTANT THRUST)
GLOBAL MM4_STAGE1_A0CONST		TO 0.
//	STAGE[1]: REFERENCE THRUST (100% POWER LEVEL)
GLOBAL MM4_STAGE1_REF_F			TO 1400000 *4 + 600000 *0.66.
//	STAGE[1]: REFERENCE ISP (100% POWER LEVEL)
GLOBAL MM4_STAGE1_REF_ISP		TO 315*0.95.
//	STAGE[1]: REMAINING LIQUID FUEL AT STAGE1 BURNOUT
GLOBAL MM4_STAGE1_BURNOUT_LF	TO 6984.
//	STAGE[1]: REMAINING OXIDIZER AT STAGE1 BURNOUT
GLOBAL MM4_STAGE1_BURNOUT_OX	TO 5714.
//	STAGE[1]: LOSS OF DRY MASS AT STAGE1 BURNOUT/SEPARATION (AKA MASS OF STAGE 1 IN KG)
GLOBAL MM4_STAGE1_BURNOUT_DRY	TO 41800.
//	STAGE[1]: POWER SETTING
GLOBAL MM4_STAGE1_POWER_SETTING	TO 1.00.

//	STAGE[2]: CONSTANT ACCELERATION (LEAVE 0 IF CONSTANT THRUST)
GLOBAL MM4_STAGE2_A0CONST		TO 0.
//	STAGE[2]: REFERENCE THRUST (100% POWER LEVEL)
GLOBAL MM4_STAGE2_REF_F			TO 600000 *0.66.
//	STAGE[2]: REFERENCE ISP (100% POWER LEVEL)
GLOBAL MM4_STAGE2_REF_ISP		TO 340.
//	STAGE[2]: POWER SETTING
GLOBAL MM4_STAGE2_POWER_SETTING	TO 1.00.

//	TARGET APOAPSIS
GLOBAL MM4_TARGET_AP			TO 80000.
//	TARGET PERIAPSIS
GLOBAL MM4_TARGET_PE			TO 80000.
//	TARGET TRUE ANOMALY
GLOBAL MM4_TARGET_TA			TO 180.

//	MAXIMUM VEHICLE PITCH RATE (DEG/SEC)
GLOBAL MM4_MAX_PITCH_RATE		TO 5.


// LOAD FLIGHT SOFTWARE
RUN OV_MM4.

// START THE OPERATING SYSTEM
ENTRYPOINT().