PRINT "Listing... (check sensors.txt in scripts folder)".
FOR PART IN SHIP:PARTS {
	LOG "Part: " + PART:TITLE + " (" + PART:NAME + ")" TO "sensors.txt".
	FOR MODULENAME IN PART:MODULES {
		SET MODULE TO PART:GETMODULE(MODULENAME).
		LOG "  Module: " + MODULENAME TO "sensors.txt".
		LOG "    Fields:" TO "sensors.txt".
		FOR FIELD IN MODULE:ALLFIELDNAMES {
			LOG "      " + FIELD TO "sensors.txt".
		}
		LOG "    Events:" TO "sensors.txt".
		FOR EVENT IN MODULE:ALLEVENTNAMES {
			LOG "      " + EVENT TO "sensors.txt".
		}
		LOG "    Actions:" TO "sensors.txt".
		FOR ACTION IN MODULE:ALLACTIONNAMES {
			LOG "      " + ACTION TO "sensors.txt".
		}
	}
}
PRINT "Finished!".