; 	Chronopolis 5k Beatfox - Csound Rhythm Generator
; 	by Micah Frank 2017
; 	www.micahfrank.com
;	https://github.com/chronopolis5k
;	micah@puremagnetik.com		

<CsoundSynthesizer>
<CsOptions>
</CsOptions>
<CsInstruments>

sr = 48000
kr = 500
nchnls = 2
0dbfs = 1.0

seed 0 
;;function tables
gi1 ftgen 1,0,129,10,1 ;sine
gi2 ftgen 2,0,129,10,1,0,1,0,1,0,1,0,1 ;odd partials
gi3 ftgen 3, 0, 16384, 10, 1, 0 , .33, 0, .2 , 0, .14, 0 , .11, 0, .09 ;odd harmonics
gi4 ftgen 4, 0, 16384, 10, 0, .2, 0, .4, 0, .6, 0, .8, 0, 1, 0, .8, 0, .6, 0, .4, 0,.2 ; saw
gi5 ftgen 5,0,129,21,1 ;white noise
gi6 ftgen 6,0,257,9,.5,1,270,1.5,.33,90,2.5,.2,270,3.5,.143,90;sinoid
gi7 ftgen 7,0,129,9,.5,1,0 ;half sine
gi8 ftgen 8,0,129,7,1,64,1,0,-1,64,-1 ;square wave
gi9 ftgen 9,0,129,7,-1,128,1 ;actually natural
gi10 ftgen     0, 0, 2^10, 10, 1, 0, -1/9, 0, 1/25, 0, -1/49, 0, 1/81
gi11 ftgen     0, 0, 2^10, 10, 1, 1, 1, 1, 1, 1, 1, 1, 1

;;set mixer levels (0 to 0.9 on last parameter)
MixerSetLevel 2, 97, 0.8 ;kick
MixerSetLevel 3, 97, 0.8 ;snare 1
MixerSetLevel 4, 97, 0.6 ;snare 2 (tuned percussion)
MixerSetLevel 5, 97, 0.4 ;hat

;grid resolution
giMasterGridRes = 4 ;(2=8th notes, 4=16th notes, 8=32nd notes, etc)

;densities
giKickdensity random 0.7,0.99  ;0 is more dense, 1 is less - default 0.7,0.9
giSnaredensity random 0.6,0.9  ;0 is more dense, 1 is less - default 0.6,0.9
giHatsdensity random 0.3,0.7  ;0 is more dense, 1 is less - default 0.3,0.7

girandomBPM init 0
gibpm init 0
giBeatsPerSec init 0

schedule 1, 0, 10000 ;prime globals
schedule 97, 0, 10000 ;prime mixer

instr globals, 1
reset:
prints "new sequence starting...\n"

girandomBPM random 75, 160 ;define bpm range - min, max
gibpm = int(girandomBPM)
giBeatsPerSec = gibpm/60 ;quarter notes per sec
giBeatDuration = 60/gibpm ;quarter note length (in seconds)
giSequenceLength = giBeatDuration*16 ; 4 bars (in seconds) 
giSteps = 16 ;number of steps in sequence. 64 = 4 bars (in steps)

ktime init 0
ktime timeinsts 
if ktime > 60/gibpm*giSteps then ;reset when elapsed time is greater than steps
	reinit reset
endif

prints "sequence length is %f seconds\n", giSequenceLength

;all instruments must be initialized so that an even can be placed therein.

schedule 98, 0, giSequenceLength ;prime sequencer
schedule 100, 0, giSequenceLength ; prime recorder

;;kick values generation
giCounter init 0
gikicksustain random 0.5, 2.0
gikickfreq random 30, 80 ;kick freq
gikickres random 0, 0.5 ;kick resonance

;;kick attack values
giatkdur random 0.15, 0.005 ; kick attack duration
giatkfreq random 80, 500 ;kick attack freq
giatklvl random 0.4, 0.8 ;attack portion level

;;snare values generation
gisnarefreq random 100, 500
gioscfreq random 200, 1000 ;primary snare freq
gisnaredur random 0.05, 0.5 
gisnareatk random gisnaredur*0.25, 0.15 ;snare attack dur
gisnarefiltinit random 5000, 10000
gisnarefiltsus random 1000, 500
gisnareres random 0.2, 0.7
gisnpenvinit random gioscfreq, 10000 ; choose p env init from freq val
gisnpenvdur random gisnaredur*.25, gisnaredur ;pith env duration
giSnaremeth random 0.2, 0.9

;;hats values generation
gihatsfreq1 random 100, 500
gihatsfreq2 random 1000, 10000
gihatsdecayshort random 0.01, 0.1
gihatsdecaylong random 0.4, 0.3

;does the hi-hat modulate?
gihatmod random 0,1
;pick hi-hat bpf freq
gihatbpf random 1000, 16000

endin

instr kick, 2

;;kick sustain
initpitch = 4
isuswave  = gi1 ;sine wave sus portion
kpenv expseg initpitch, giatkdur, 1, gikicksustain-giatkdur, 1  ;modulate sustain pitch for attack dur

kamp expseg 0.5, gikicksustain, 0.001

;;kick attack
iatkwave = gi8 ; attack wave
katkenv expseg giatklvl, giatkdur, 0.01 ;attack envelope

asus oscili kamp, gikickfreq*kpenv, isuswave
aatk oscili katkenv, giatkfreq, iatkwave

kfiltenv expseg 3000, gikicksustain, 20

afilteredsig moogvcf2 asus + aatk, kfiltenv, gikickres

MixerSend afilteredsig, 2, 97, 0

endin


instr snare1, 3
ifn  = gi1
irandomAmp random 0.1, 0.5
kamp expseg irandomAmp, gisnaredur, 0.001
kampNoise expseg irandomAmp, gisnaredur*0.5, 0.001 ;make noise portion 1/2 length of snare
ksnpenv expseg gisnpenvinit, gisnpenvdur, 0.001 ; snare pitch envelope
asnare oscili kamp, gisnarefreq, ifn
kfiltenv expseg gisnarefiltinit, gisnareatk, gisnarefiltsus, gisnaredur-gisnareatk, gisnarefiltsus
anoise noise kampNoise, 0
afilteredsig moogvcf2 anoise + asnare, kfiltenv, gisnareres
MixerSend afilteredsig, 3, 97, 0


endin

instr snare2, 4
ifn  = gi1
irandomAmp random 0.1, 0.5

iSnare2_rand1 random 0, 2
iSnare2_rand2 random 0, 1
iSnare2_rand3 random 0, 1

kamp expseg irandomAmp, gisnaredur*iSnare2_rand1, 0.001
ksnpenv expseg gisnpenvinit, gisnpenvdur*iSnare2_rand2, 0.001 ; snare pitch envelope
asig oscili kamp, gisnarefreq*iSnare2_rand3, ifn
asnare pluck kamp, gisnarefreq*iSnare2_rand1, gisnarefreq, 0, 3, giSnaremeth
kfiltenv expseg gisnarefiltinit, gisnareatk, gisnarefiltsus, gisnaredur-gisnareatk, gisnarefiltsus

afilteredsig moogvcf2 asig + asnare, kfiltenv, gisnareres

MixerSend afilteredsig, 4, 97, 0



endin

instr hats, 5
irandomAmp random 0.1, 0.3
;decide whether "closed" or "open" hat
iclosedOrOpen random 0,1
ihatdecay = iclosedOrOpen > 0.9 ? gihatsdecaylong : gihatsdecayshort
ifn  = gi5 ;noise 
kamp linseg irandomAmp, ihatdecay, 0.001
ahat1 oscili kamp, gihatsfreq1, ifn
ahat2 oscili kamp, gihatsfreq2, ifn

;SHOULD PROB CHANGE SAMPLE & HOLD DURS TO MATCH NOTE LENGTH!!!

if gihatmod > 0.5 then
	kmodfreq randomh 500, -600, 0.2, 3
	else
	kmodfreq = 1
endif

alow, ahigh, aband svfilter ahat1 + ahat2, gihatbpf + kmodfreq, 100 

MixerSend ahat1 + ahat2, 5, 97, 0


endin 

instr mixer, 97
;;mixer receive section

	amix MixerReceive 97, 0
	a1 limit amix, -0.6, 0.6 ;limit weird shit
	outs a1, a1
	MixerClear

endin


instr drumsSeq, 98
iGridRes1 = giBeatsPerSec * giMasterGridRes
ktrig metro iGridRes1 ;metronome triggers 16th notes

if ktrig = 1 then
	;make random values for voice that decide against density value
	kKickDecider random 0, 1
	kSnare1Decider random 0, 1
	kSnare2Decider random 0, 1
	kHatDecider random 0, 1
	
	if kKickDecider > giKickdensity then
		event "i", "kick", 0, iGridRes1
	endif
	
	if kSnare1Decider > giSnaredensity then
		event "i", "snare1", 0, iGridRes1		
	endif
	
	if kSnare2Decider > giSnaredensity then
		event "i", "snare2", 0, iGridRes1		
	endif
	
	if kHatDecider > giHatsdensity then
		event "i", "hats", 0, 1		
	endif
	
endif	

endin

instr recorder, 100
;; random word generator
icount init 0
iwordLength random 2,4 ; how long will the random word be (when this number is doubled)
iwordLength = int(iwordLength)
StringAll =       "bcdfghjklmnpqrstvwxz"
StringVowels =     "aeiouy"
Stitle = ""
cycle:
if icount < iwordLength then 
	irandomLetter  random 1,20
	irandomVowel  random 1,6	
	Ssrc1 strsub StringAll, irandomLetter,irandomLetter+1
	Ssrc2 strsub StringVowels, irandomVowel,irandomVowel+1
	Ssrc1 strcat Ssrc1, Ssrc2 ; combine consonants and vowels
	Stitle strcat Stitle, Ssrc1 ;add to previous string iteration
                icount += 1
                goto cycle
endif

allL, allR monitor

;;file writing
Sfilename sprintf "%ibpm-", gibpm
Sfilename strcat Sfilename,Stitle 
Sfilename strcat  Sfilename, ".aif"
fout Sfilename, 24, allL, allR 

endin


</CsInstruments>
<CsScore> 

</CsScore>
</CsoundSynthesizer>
<bsbPanel>
 <label>Widgets</label>
 <objectName/>
 <x>100</x>
 <y>100</y>
 <width>320</width>
 <height>240</height>
 <visible>true</visible>
 <uuid/>
 <bgcolor mode="nobackground">
  <r>255</r>
  <g>255</g>
  <b>255</b>
 </bgcolor>
</bsbPanel>
<bsbPresets>
</bsbPresets>
