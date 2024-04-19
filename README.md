BANZDEMO
========

Enhanced port to DLang of the Apple Pascal Banzhaf Index calculator
from the March 1984 issue of Byte Magazine. Mostly intended as a
learning project for D.

Original project specified it's runtime options conversationally from
the user.  It would take input from either a file specified or via a
simple data entry UI at the keyboard, and output was in one format
only, with an option to send to the printer.  There was also a lot of
status output. Internally it was limited to a maximum of 10 ID block
lines and 200 parties. The original used the standard Apple 2 ROM
floats, which were very low precision and slow and prone to rounding
errors.

Since I am retargeting to a POSIX system, the input now always comes
from stdin, the output goes to stdout, and any status output goes to
stderr.  There is no UI for entry at the keyboard, and it takes 3
input file formats: the original(bytemag), tab delimited (tab), ~~and
CSV(csv)~~. Options are specified with command line switches and not
conversationally. No printing, people don't print much anymore and
that is what lpr(1) is for. I'm also using the D double precision
(IEEE 754) floats, as opposed to the tiny precision non-standard
Apple 2 floats.

The portions of the banhaf-byte repo that are my (John Dougan) work
are licensed under the GPL 2.0. Everything else is under their
respective copyrights, particularly the original code by Philip A.
Schrodt. 


Options
-------
```
banzdemo --mwc=NUM 
	--process=(all|montecarlo)
	--informat=(bytemag|tab|csv) --header=(none|columns|all) 
	--seed=NUM --nex=NUM   < infile > outfile
```

`--process` specifies if processing is be be exhaustive (`all`) or
monte carlo random sampling (`montecarlo`). Defaults to `all`.
Depending on the computer performance, `--process=all` with more than
29 or so parties can take more than a few minutes.

`--mwc` is minimum winning coalition and the the smallest number of
votes necessary to win a vote in the data set. Specified externally
so you can easily rerun for super-majorities without changing the
data set. There is no default, if not set `banzdemo` will crash on a
zero test assertion.

`--seed` seeds the PRNG for reproducible runs.  It is ignored if
processing exhaustively.  If not present, it defaults to Phobos'
`std.random.unpredictableSeed()`.  `--nex` specifies how many Monte
Carlo runs (Number of EXperiments).  It is also ignored if processing
exhaustively.  If unspecified then it defaults to 1,048,576
(2^20) runs.

Input format `--informat` is one of 3 values: `bytemag`
(default), `tab`, or `csv`. Descriptions are below.

The output format is a tab delimited table formatted so it can
potentially be used as input again, once any optional headers are
romoved.  The first 2 columns are PartyName and Votes, and the rest
are Banzhaf calculation data matching the original Pascal program
output. The `--header` switch specifies how much header is output:
nothing at all (`none`), just column labels (`columns`), or both the ID block and column
labels (`all`)(default). If no headers, then the output file is suitable to be used
as tab delimited input.

Bytemag file format
--------------------
The bytemag format consists of a block of lines of identifying
information, followed by an empty line separatior. If there are zero
line of id, then the file still must contain the empty line
separator.

This is followed by a block of lines that each have 2 fields separated
by a colon: party name label, and the number of votes they command
(base 10 integer). Extra spaces at the beginning and end of the
fields are trimmed. This block can either be ended by a empty line or
the end of the file.

eg.
```
Italian 1983 Parliament
Sample data from BYTE article

Small regional parties:6
Christian Democrats : 255 
Communist: 198
 Socialist :73
Italian Social Movement:48
Republican:29
Democratic Socialist:23
Liberal:16
Radical:11
Proletarian Democrats:7 
```

Minimum file:
```

a:1
```

Tab Delimited
-------------
This is used for both input and output. Tab is a file of line records,
with the record fields on a line separated by single tab. All of the
record lines must have 2 or more entries (with the first 2 bring
Party Name and Vote Num) and the remainder of the fields are ignored
on input. CSV should be similar, but in CSV format.

Columns on output: 

`PartyName Votes VoteProp NumPivots BanzIndex BI-VP BI/VP`

input example.
```
Small regional parties	6
Christian Democrats	255 
Communist	198
 Socialist	73 
Italian Social Movement	48
Republican	29
Democratic Socialist	23
Liberal	16
Radical	11
Proletarian Democrats	7 
```

also as output:
```
Christian Democrats	255	0.382883	359	0.403371	0.0204879	1.05351
Communist	198	0.297297	153	0.17191	-0.125387	0.578243
Socialist	73	0.10961	149	0.167416	0.0578061	1.52738
Italian Social Movement	48	0.0720721	87	0.0977528	0.0256807	1.35632
Republican	29	0.0435435	41	0.0460674	0.00252387	1.05796
Democratic Socialist	23	0.0345345	35	0.0393258	0.00479131	1.13874
Liberal	16	0.024024	25	0.0280899	0.00406586	1.16924
Radical	11	0.0165165	21	0.0235955	0.00707899	1.4286
Proletarian Democrats	7	0.0105105	11	0.0123596	0.00184904	1.17592
Small regional parties	6	0.00900901	9	0.0101124	0.00110335	1.12247
```

CSV
---
Not yet specified, should be a lot like tab delimited.

Current Issues
---------------
- Was built using the gcc dlang compiler, gdc. There may be some gdc-isms I am unaware of.
- Similarly, the Makefile is dependent on gdmd to invoke compilation.
	- Should make it easy to use dmd on systems with that.
- CSV input not yet done.
	- Maybe drop CSV input and rely on other tools (awk?) to convert to tab delimited?
	- Or not. It gives me a chance to mess with std.csv.
- Might want to make input and output switches more orthogonal
	- Separeate header output into labels and id block switches
	- Same for input?
- Proportional mwc calc needs revision and command line switches.
- Error handling for getopt.
	- Currently it'll crash if you miss-specify options.
- An option to skip any column headers in the csv or tab input would be useful.
	- Possibly a `--inskip=NUMLINES`
- Look for some way to do D I/O without the GC or exceptions.
- The Pascal source file has many, many OCR errors.
	- Find an Apple Pascal compatible compiler and make it work.
- Put the data in the global space instead of the thread local space and benchmark?
- Float output formatting needs to be more fully specified, or there is a decent chance some tests will incorrectly fail.
- Need doc on updating test cases if they fail due to reformatting.

Done
----------
- DONE Currently depends on a private library for a lame sort algo. Should remove dependency.
	- ceres.sorting needs reworking anyways
	- Went back to the weird sort from the original. Not efficient, but at most only a few thousand Parties in any real worls scanario.
- DONE Calculations on Italian votes don't match sample data in original article.
	- Checked against textbook examples, and program is correct.
  	- To be fair, I'm not sure they were supposed to. It might have been monte carlo processed.
  	- It also doesn't match other sources.
  	- Try different values for mwc: 333,334,??? and see if it matches other outputs better?
  	- Go over processing code again, maybe I missed something.
- DONE Montecarlo not done yet.
	- DONE It will need a `--seed=`switch to seed the random numbers.
	- DONE Also needs an `--nex=` swirch to specify number of experiments
	- DONE See how Phobos handles pseudo-random numbers.
		- answer is "with @gc"!
	- DONE My PRNG needs an actual random seeding method. Currently just sets the seed to 0 if not specified.


Compiler Version
-----------------
From std.compiler:
```
Compiler-Name: GNU D
Vendor: gnu
Vendor-Version: 2.76
D-Version: 2
```

from gdc --version
```
gdc (Ubuntu 11.4.0-1ubuntu1~22.04) 11.4.0 
Copyright (C) 2021 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```


