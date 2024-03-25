NOTES.md
========
Port to DLang of the Apple Pascal Banzhaf Index calculator from the March 1983 issue of Byte Magazine. Mostly intended as a learning project for D.

- Byte magazine 1983:
	- https://ia800308.us.archive.org/20/items/byte-magazine-1984-03/1984_03_BYTE_09-03_Simulation.pdf
- Looking at the output, the sample data in Byte doesn't match eithe my output or that of pne of the online banzhaf calculators.
- 
- Try an online banhaf index calculator to check correctness it seems pretty
clear that the sample data from Byte has either ENORMOUS rounding error from the terrible Applesoft FP or is a
different run.
	- https://www.google.com/search?q=online+banzhaf+index+calc&oq=online+banzhaf+index+calc&gs_lcrp=EgZjaHJvbWUyBggAEEUYOTIICAEQABgWGB7SAQg3NDgxajBqN6gCALACAA&sourceid=chrome&ie=UTF-8
	- https://mywebpages.csv.warwick.ac.uk/cgi-vpi/ipgenf.cgi
	- https://homepages.warwick.ac.uk/~ecaae/ipgenf.html
	- https://gist.github.com/HeinrichHartmann/8ec2e2245f2a70441257
	- 

- Try different values for mwc: 333,334,??? and see if it matched others output better
- XXX do easy options: headerX, mwcX, ???

- Montecarlo not done yet
- csv input not done yet
- think about other output formats, like CSV
- Proportional mwc calc needs revision and command line switvhes.
- error handling for getopt
- 

