#
# Banzdemo Makefile
# John Dougan
#
#
PROGRAMS=banzdemo
TESTOUTDIR=testoutput
TESTINDIR=testinput

# will want to change this on a standard D system
DCC=gdmd
DOPTS=-g -gs 

all:  $(PROGRAMS)
	echo Default actions, build the program. make alltests to buid and run the tests.

banzdemo: banzdemo.d 
	$(DCC) banzdemo.d $(DOPTS)

#
# Testing
#
alltests: testIT testltext montecarlotest

#
# Parsing and output tests
#
testIT: banzdemo $(TESTINDIR)/Votes-IT.banzbyte testoutdir 
	mkdir -p $(TESTOUTDIR)
	./banzdemo --mwc 334 --header=all < $(TESTINDIR)/Votes-IT.banzbyte  > $(TESTOUTDIR)/Votes-IT-out1.txt
	./banzdemo --mwc 334 --header=columns < $(TESTINDIR)/Votes-IT.banzbyte  > $(TESTOUTDIR)/Votes-IT-out2.txt
	./banzdemo --mwc 334 --header=none < $(TESTINDIR)/Votes-IT.banzbyte  > $(TESTOUTDIR)/Votes-IT-out3.tab
	./banzdemo --mwc 334 --header=none --informat=tab < $(TESTOUTDIR)/Votes-IT-out3.tab  > $(TESTOUTDIR)/Votes-IT-out4.tab
	diff  $(TESTOUTDIR)/Votes-IT-out3.tab  $(TESTOUTDIR)/Votes-IT-out4.tab

#
# ltext : known correct exhaustive examples from textbook
#
LTEXTTESTOUTPUT=$(TESTOUTDIR)/Banz-ltext4-mwc8.tab $(TESTOUTDIR)/Banz-ltext5-mwc16.tab $(TESTOUTDIR)/Banz-ltext6-mwc65.tab $(TESTOUTDIR)/Banz-ltext7-mwc58.tab

regenerateLtextTestTargets: testoutdir $(LTEXTTESTOUTPUT)
	cp $(LTEXTTESTOUTPUT) $(TESTINDIR)/

testltext: testoutdir $(LTEXTTESTOUTPUT)
	diff $(TESTOUTDIR)/Banz-ltext4-mwc8.tab  $(TESTINDIR)/Banz-ltext4-mwc8.tab
	diff $(TESTOUTDIR)/Banz-ltext5-mwc16.tab $(TESTINDIR)/Banz-ltext5-mwc16.tab
	diff $(TESTOUTDIR)/Banz-ltext6-mwc65.tab $(TESTINDIR)/Banz-ltext6-mwc65.tab
	diff $(TESTOUTDIR)/Banz-ltext7-mwc58.tab $(TESTINDIR)/Banz-ltext7-mwc58.tab

$(TESTOUTDIR)/Banz-ltext4-mwc8.tab: banzdemo $(TESTINDIR)/Votes-ltext4.banzbyte
	./banzdemo --mwc=8 --header=none < $(TESTINDIR)/Votes-ltext4.banzbyte  > $(TESTOUTDIR)/Banz-ltext4-mwc8.tab

$(TESTOUTDIR)/Banz-ltext5-mwc16.tab: banzdemo $(TESTINDIR)/Votes-ltext5.banzbyte
	./banzdemo --mwc=16 --header=none < $(TESTINDIR)/Votes-ltext5.banzbyte  > $(TESTOUTDIR)/Banz-ltext5-mwc16.tab

$(TESTOUTDIR)/Banz-ltext6-mwc65.tab: banzdemo $(TESTINDIR)/Votes-ltext6.banzbyte
	./banzdemo --mwc=65 --header=none < $(TESTINDIR)/Votes-ltext6.banzbyte  > $(TESTOUTDIR)/Banz-ltext6-mwc65.tab

$(TESTOUTDIR)/Banz-ltext7-mwc58.tab: banzdemo $(TESTINDIR)/Votes-ltext7.banzbyte
	./banzdemo --mwc=58 --header=none < $(TESTINDIR)/Votes-ltext7.banzbyte  > $(TESTOUTDIR)/Banz-ltext7-mwc58.tab

#
# Monte Carlo Tests
#
MCOPTS=--informat=tab --process=montecarlo --nex=1000000 --seed=0 

montecarlotest: banzdemo testoutdir $(TESTINDIR)/US-Electoral-College-2024.tsv 
	./banzdemo --mwc=270 $(MCOPTS) --header=all < $(TESTINDIR)/US-Electoral-College-2024.tsv  > $(TESTOUTDIR)/Banz-USEC-nex1_000_000.txt
	./banzdemo --mwc=270 $(MCOPTS) --nex=10000000 --header=all < $(TESTINDIR)/US-Electoral-College-2024.tsv  > $(TESTOUTDIR)/Banz-USEC-nex10_000_000.txt

#
# utility
#

testoutdir:
	mkdir -p $(TESTOUTDIR)

clean:
	rm -rf *.o banzdemo $(TESTOUTDIR)/*

allclean: clean
	rm -rf $(TESTOUTDIR)
