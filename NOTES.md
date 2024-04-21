# NOTES.md 

Port to DLang of the Apple Pascal Banzhaf Index calculator from the
March 1983 issue of Byte Magazine. Mostly intended as a learning
project for D.

## Notes

- Byte magazine 1983:
	- https://ia800308.us.archive.org/20/items/byte-magazine-1984-03/1984_03_BYTE_09-03_Simulation.pdf
- Looking at the output, the sample data in Byte doesn't match eithe my output or that of pne of the online banzhaf calculators.
	- Try an online banhaf index calculator to check correctness it seems pretty clear that the sample data from Byte has either ENORMOUS rounding error from the terrible Apple ROM FP or is a monte carlo run.
	- https://www.google.com/search?q=online+banzhaf+index+calc&oq=online+banzhaf+index+calc&gs_lcrp=EgZjaHJvbWUyBggAEEUYOTIICAEQABgWGB7SAQg3NDgxajBqN6gCALACAA&sourceid=chrome&ie=UTF-8
	- https://mywebpages.csv.warwick.ac.uk/cgi-vpi/ipgenf.cgi
	- https://homepages.warwick.ac.uk/~ecaae/ipgenf.html
	- https://gist.github.com/HeinrichHartmann/8ec2e2245f2a70441257
	- https://math.libretexts.org/Bookshelves/Applied_Mathematics/Math_in_Society_(Lippman)/03%3A_Weighted_Voting/3.04%3A_Calculating_Power-__Banzhaf_Power_Index
		- Using these textbook examples, we are getting correct answers.
	- DONE Try different values for mwc: 333,334,??? fr IT data and see if it matches

- The US Electoral College dataset will take too long on `--process=all1
	- Would need to do 2^51 coalitions
	- For me, 2^25 coalitions takes about 26 seconds. (cpu single thread)
	- So, full run would take 2^26 * 26 seconds == somewhere over 55 years.
	- `time -p ./banzdemo --mwc=270 --informat=tab --process=montecarlo --seed=0  --nex=33554432  --header=columns < testinput/US-Electoral-College-2024.tsv  > Banz-USEC-seed0-nex2r25.txt > Banz-USEC2024-mwc270-nex2r25.tab`
	- Would be amusing to feed it to a *big* map/reduce cluster.

- AWK Language ref
	- https://www.ibm.com/docs/en/aix/7.2?topic=awk-command

## open

- GITHUB integration, run tests on push?
- --verbose option
- CSV
	- CSV input not done yet
	- think about other output formats, like CSV
	- is there another tool that can handle the conversion?
		- goAwk
		- true awk
		- recent gawk
- Proportional mwc calc needs revision and command line switches.
	- Turned off for now
	- --mwc=majority 1/2 + on ties
	- --mwc=NUM
	- --mec=2/3  supermajority.  is it > or >=??
	- --mwc=1/1  unaminity we can shortfut the calc.
- Array of bool is unpacked in bytes.
	- https://www.cppstories.com/2017/04/packing-bools/
	- Maybe pack it.
		- it should keep the size in many cases under a cacheline.
		- with a ressonable set of packing/upacking instructions it should be cache compatible.
	- D has a BitArray, try that first.
- I badly want an assert that lets me specify a POSIX exit code on failure.
	- `exitassert(totalVotes < 1, "TotalVotes < 1", EXIT_BADDATA);`
- `./banzdemo --mwc=21  <  testinput/Votes-ltext5.banzbyte`    

## closed-ish

- DONE do easy options: headerX, mwcX, ???
- DONE Montecarlo 
	- WTF is Phobos doing with std.random.uniform() being @gc!?
- DONE error handling for getopt
	- If we just give up and jusr make the parser `@safe` it should be easy.
- DONE Issue warning if monte carlo and mwc == totalVotes (unanimity)?
	- it won't get it right without a lucky hit on the single 
	- all will work, but could take a while
	- there is only one coalition that will work, the one that everyone is in. if anyone defects, the vote sill fail. So, everyone has the same NumPivots and totalPivots, which means the same BI.
	- DONE Add a a special case?
		- set up the Coalitions to all true.
		- countpivots
		- the continue to banzcomp as usual.
- DONE if mwc = 0, then error
	- right now it fails on an assert, make it work a bit better?
	- Now exits with a message to stderr, and an appropriate status code.

## compiler

Compiler-Name: GNU D
Vendor: gnu
Vendor-Version: 2.76
D-Version: 2
```
