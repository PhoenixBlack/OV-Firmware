SWITCH TO ARCHIVE.

RUN INSTALL_RTSK.

COMPILE OV_STS.KS TO OV_STS.KSM.
COMPILE OV_MM1.KS TO OV_MM1.KSM.
COMPILE OV_MM2.KS TO OV_MM2.KSM.
COMPILE OV_MM3.KS TO OV_MM3.KSM.
COMPILE OV_MM5.KS TO OV_MM5.KSM.
COMPILE OV_MM6.KS TO OV_MM6.KSM.

COPYPATH("0:/OV_STS.KSM",		"1:").
COPYPATH("0:/OV_MM1.KSM",		"1:").
COPYPATH("0:/OV_MM2.KSM",		"1:").
COPYPATH("0:/OV_MM3.KSM",		"1:").
COPYPATH("0:/OV_MM5.KSM",		"1:").
COPYPATH("0:/OV_MM6.KSM",		"1:").

SWITCH TO 1.