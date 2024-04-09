#
#
#
#
#
PROGRAMS = banzdemo
TESTOUTPUT = 

# will want to change this on a standard D system
DCC=gdmd

all: test testca $(PROGRAMS) $(TESTOUTPUT) 
	# echo Default actions, build all the tests.

banzdemo: banzdemo.d 
	$(DCC) banzdemo.d 

test: banzdemo Votes-IT.banzbyte
	./banzdemo --mwc 334 --header=all < Votes-IT.banzbyte  > Votes-IT-out1.txt
	./banzdemo --mwc 334 --header=columns < Votes-IT.banzbyte  > Votes-IT-out2.txt
	./banzdemo --mwc 334 --header=none < Votes-IT.banzbyte  > Votes-IT-out3.tab
	./banzdemo --mwc 334 --header=none --informat=tab < Votes-IT-out3.tab  > Votes-IT-out4.tab
	diff  Votes-IT-out3.tab  Votes-IT-out4.tab

testca: banzdemo Votes-IT.banzbyte
	./banzdemo --mwc 51 --header=none < Votes-CA.banzbyte  > Votes-CA-out1.tab

clean:
	rm -rf *.o banzdemo Votes-IT-out*.txt Votes-IT-out*.tab Votes-CA-out*.txt Votes-CA-out*.tab

allclean: clean
	echo 