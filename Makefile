#
#
#
#
#
PROGRAMS = banzdemo
TESTOUTPUT = 

# will want to change this on a standard D system
DCC=gdmd
DOPTS=

all: test testca $(PROGRAMS) $(TESTOUTPUT) 
	# echo Default actions, build all the tests.

banzdemo: banzdemo.d 
	$(DCC) banzdemo.d $(DOPTS)

test: banzdemo Votes-IT.banzbyte
	mkdir -p testoutput
	./banzdemo --mwc 334 --header=all < Votes-IT.banzbyte  > testoutput/Votes-IT-out1.txt
	./banzdemo --mwc 334 --header=columns < Votes-IT.banzbyte  > testoutput/Votes-IT-out2.txt
	./banzdemo --mwc 334 --header=none < Votes-IT.banzbyte  > testoutput/Votes-IT-out3.tab
	./banzdemo --mwc 334 --header=none --informat=tab < testoutput/Votes-IT-out3.tab  > testoutput/Votes-IT-out4.tab
	diff  testoutput/Votes-IT-out3.tab  testoutput/Votes-IT-out4.tab

testca: banzdemo Votes-IT.banzbyte
	./banzdemo --mwc 51 --header=none < Votes-CA.banzbyte  > testoutput/Votes-CA-out1.tab

clean:
	rm -rf *.o banzdemo testoutput/*

allclean: clean
	rm -rf testoutput
