# OV-FIRMWARE/RTSK

RTSK (RealTime System for Kerbals) is a realtime OS for control and guidance of space vehicles written for kOS. It comes with firmware for a space shuttle vehicle (or a similar winged/lifting vehicle).

While it's supposed to be flexbile and reconfigureable, currently the software is only included for parallel-staging STS or Buran like vehicle. It uses iterative guidance for ascent and re-entry to support launching and returning payloads in a wide range of initial values.

The shuttle guidance is designed to be fully automatic in ascent, re-entry and landing.

# Included Software
- `MAJOR MODE 1`: parallel-staging ascent guidance
- `MAJOR MODE 2`: on-orbit operations software supporting station-keeping, precise docking and some other operations (rendezvous etc)
- `MAJOR MODE 3`: approach and landing guidance for a safe automatic landing back at KSC
- `MAJOR MODE 5`: abort guidance (return to launch site, abort to orbit, water ditch abort)
- `MAJOR MODE 6`: iterative terminal re-entry guidance