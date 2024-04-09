ARCHITECTURE.md
================

This is mostly a copy of the Apple Pascal program's processing stages, which were mostly organized to deal with the limitations of the host platform (the very slow p-machine, and not a lot of RAM). There are some other organizational weirdnesses (read stage did the sorting, and some duplicate code) that I have adjusted.

The data space is preallocated as thread local values, as D does by default. I'm considering making them global just to benchmark the performance differences. This may be parallelizable.

I'm not going to explain Banzhaf Indexes here. The original Byte article isn't actually too bad. and is easily available online at the Internet Archive. ( https://archive.org/details/byte-magazine-1984-03-rescan/page/n139/mode/2up )

The core data consistes of 5 parallel arrays and a handful of counters and totals. The arrays' key denotes a particular Party name,Votes pair in the sorted input. Almost everything is indexed from [1..np] as that is what the original did and was just easier to make the arrays 1 element larger and let the 0 offset be unused.

## Misc Data
- np
	- Number of (PartyName, Vote) from the input.
- totvote
	- Sum of all the votes
- ncex
	- Number of coalition evaluated.
- nex
	- Sum of all the entries in Votes[].
- mwcvote
	- Minimum winning coalition, the smallest number of votes to win.
	- There are some subtleties in this.
	- eg. you may need to add 1 of the voting rules say more than. If we have a parliament witha total number of votes of 100, then if the rule is more than half, you will need mwcvote to be set to 51.
	- set from the command line.
- totpivots
	- running total of the number of pivot events
- npp1
	- Is np + 1. Used to avoid recalulation in the original.
- nid
	- Number of lines in the ID block.
- IdHeader
	- Array of string, used to store the lines of the ID block in the bytemag input format. 
	- We are storing the ID block in the customary fashion, starting from 0.

## Parallel Arrays
- PartyNames
	- `string` trimmed from the input
- Votes
	- `int` trimmed from the input.
- NumPivots
	- `int` is the count of times the PartyName[ka] was potentially pivotal in a vote. 
- CoalitionMember
	- This is an array of `bool` handled in an ususual way. A given bit pattern of this represents a voting coalition where for each CoalitionMember[ka] being true means that PartyName[ka] in in the currently evaluated coalition and could potentially be pivotal.
	 - The main loop in the Exhaustive processing option just incremants this by calling `allcoal()`. 
	- It also is one element longer than the others. This is effectively a carry bit, so if it is set you know you iterated through all possible combinations of the lower bits.
- BanzIndex
	- `double` is the ratio of NumPivots/TotalPivots and ic calculated in the last stage, banzcalc.


## The processing stages
- setFromCommandFlags()
	- 
- init()
	- Clears out `NumPivots` to 0.
- readdata()
	- read from stdin, interpreting based on `--informat` option.
	- output into `np`, `Votes`, `PartyNames`.
	- Header data into `nid`, `IdHeader` if present. therwise nid = 0.
- massage()
	- Calculate needed values from the inputs.
	- Calculates `nex`, `npp1`
	- If using a proportion to calculate `mwcvote`, compute it here.
	- Sorts the data by `Votes` descending, this enables a processing shortcut.
	- The sort is very lame.
- Either of, based on the `--process` option.
	- randcomp()
		- Monto Carlo testing.
	- exhaust()
		- Interate through all possible combinations.
- banzcomp()
	- Late stage processing
	- Sum the total pivots from NumPivots
	- Compute the BanzIndex for each entry.
- banzprint()
	- Output the results to stdout






