NOTES.md ======== Port to DLang of the Apple Pascal Banzhaf Index
calculator from the March 1983 issue of Byte Magazine. Mostly
intended as a learning project for D.

- Byte magazine 1983:
	- https://ia800308.us.archive.org/20/items/byte-magazine-1984-03/1984_03_BYTE_09-03_Simulation.pdf
- Looking at the output, the sample data in Byte doesn't match eithe my output or that of pne of the online banzhaf calculators.
- 
- Try an online banhaf index calculator to check correctness it seems pretty clear that the sample data from Byte has either ENORMOUS rounding error from the terrible Apple ROM FP or is a different run.
	- https://www.google.com/search?q=online+banzhaf+index+calc&oq=online+banzhaf+index+calc&gs_lcrp=EgZjaHJvbWUyBggAEEUYOTIICAEQABgWGB7SAQg3NDgxajBqN6gCALACAA&sourceid=chrome&ie=UTF-8
	- https://mywebpages.csv.warwick.ac.uk/cgi-vpi/ipgenf.cgi
	- https://homepages.warwick.ac.uk/~ecaae/ipgenf.html
	- https://gist.github.com/HeinrichHartmann/8ec2e2245f2a70441257
	- https://math.libretexts.org/Bookshelves/Applied_Mathematics/Math_in_Society_(Lippman)/03%3A_Weighted_Voting/3.04%3A_Calculating_Power-__Banzhaf_Power_Index
		- Using these textbook examples, we are getting correct answers.
	- Try different values for mwc: 333,334,??? fr IT data and see if it matches

- This will take too long on exhaustive
	- ./banzdemo --mwc=270 --header=all  < testinput US-Electoral-College-2024.tsv > Banz-USEC2024-mwc270.tab
- AWK Language
	- https://www.ibm.com/docs/en/aix/7.2?topic=awk-command

- XXX do easy options: headerX, mwcX, ???

- Montecarlo not done yet
- csv input not done yet
- think about other output formats, like CSV
- Proportional mwc calc needs revision and command line switches.
- error handling for getopt
- Array of bool is unpacked in bytes.
	- https://www.cppstories.com/2017/04/packing-bools/
	- Maybe pack it.
		- it should keep the size in many cases under a cacheline.
		- with a ressonable set of packing/upacking instructions it should be pipeline compatible.
	- D has a BitArray, try that first

Compiler-Name: GNU D
Vendor: gnu
Vendor-Version: 2.76
D-Version: 2
