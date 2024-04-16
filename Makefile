#
#
#
#
#
PROGRAMS=banzdemo
TESTOUTDIR=testoutput
TESTINDIR=testinput
#TESTOUTPUT = testoutput/Votes-IT-out1.txt testoutput/Votes-IT-out2.txt testoutput/Votes-IT-out3.tab testoutput/Votes-IT-out4.tab
TESTOUTPUT=

# will want to change this on a standard D system
DCC=gdmd
DOPTS=-g -gs 

all:  $(PROGRAMS) test $(TESTOUTPUT) testltext
	# echo Default actions, build all the tests.

banzdemo: banzdemo.d 
	$(DCC) banzdemo.d $(DOPTS)

test: banzdemo $(TESTINDIR)/Votes-IT.banzbyte testltext testoutdir 
	mkdir -p $(TESTOUTDIR)
	./banzdemo --mwc 334 --header=all < $(TESTINDIR)/Votes-IT.banzbyte  > $(TESTOUTDIR)/Votes-IT-out1.txt
	./banzdemo --mwc 334 --header=columns < $(TESTINDIR)/Votes-IT.banzbyte  > $(TESTOUTDIR)/Votes-IT-out2.txt
	./banzdemo --mwc 334 --header=none < $(TESTINDIR)/Votes-IT.banzbyte  > $(TESTOUTDIR)/Votes-IT-out3.tab
	./banzdemo --mwc 334 --header=none --informat=tab < $(TESTOUTDIR)/Votes-IT-out3.tab  > $(TESTOUTDIR)/Votes-IT-out4.tab
	diff  $(TESTOUTDIR)/Votes-IT-out3.tab  $(TESTOUTDIR)/Votes-IT-out4.tab

testoutdir:
	mkdir -p $(TESTOUTDIR)

clean:
	rm -rf *.o banzdemo $(TESTOUTDIR)/*

allclean: clean
	rm -rf $(TESTOUTDIR)

#
# known correct examples from textbook
#

testltext: testoutdir $(TESTOUTDIR)/Banz-ltext4-mwc8.tab $(TESTOUTDIR)/Banz-ltext5-mwc16.tab $(TESTOUTDIR)/Banz-ltext6-mwc65.tab $(TESTOUTDIR)/Banz-ltext7-mwc58.tab
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



