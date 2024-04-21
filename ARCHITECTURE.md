ARCHITECTURE.md
================

This is mostly a copy of the Apple Pascal program's processing stages,
which were mostly organized to deal with the limitations of the host
platform (Apple ][ limits like printing and no command line args, the
very slow p-machine, and not a lot of RAM). There are some other
organizational weirdnesses (read stage did the sorting, and some
duplicate code) that I have adjusted.

I'm not going to explain Banzhaf Indexes here. The original Byte
article isn't actually too bad. and is easily available [online at
the Internet Archive].
(https://archive.org/details/byte-magazine-1984-03-rescan/page/n139/mode/2up)

The core data consists of 5 parallel arrays and a handful of counters
and totals. These structures are operated on in-place by a series of
functions. The parallel arrays' key denotes a particular
(Party name,Votes) pair in the sorted input. Almost everything is
indexed from [1..np] as that is what the original did and was just
easier to make the arrays 1 element larger and let the 0 offset be
unused.

The data space is preallocated as thread local values, as D does by
default. I'm considering making them global just to benchmark the
performance differences. This may be parallelizable.

If error returns are needed, the function is question will return an
`int` exit code, where EXIT_NOERROR == 0. If necessary that code will
be used as the process exit code. The constants are at the top of the
file. It may also write to stderr, but so far it doesn't. 

## Misc Data
- np
	- Number of (PartyName, Vote) from the input.
- ncex
	- Number of coalitions evaluated.
	- Orignallly used for progress reporting, currently not used.
- nex
	- Number of EXperiments.
	- The number of coaltion to be tested in Monte Carlo.
- mwcvote
	- Minimum winning coalition, the smallest number of votes to win.
	- There are some subtleties in this.
	- eg. you may need to add 1 of the voting rules say more than. If we have a parliament witha total number of votes of 100, then if the winning rule is a majority, you will need mwcvote to be set to 51.
	- set from the command line.
- totpivots
	- total of the number of pivot events
	- Sum of NumPivots[].
- npp1
	- Is np + 1. Used to avoid recalulation in the original.
- nid
	- Number of lines in the ID block.
- IdHeader
	- Array of string, used to store the lines of the ID block in the bytemag input format. 
	- We are storing the ID block in the customary fashion, starting from 0.
- totalVotes
	- Sum of all the entries in Votes[].
	- Should be > 0.
- monteCarloGen
	- MT19337 32 bit PRNG\
- unanimityFlag
	- Indicates tha mwcvote == total votes, which is handled in a fast shortcut.

## Parallel Arrays
- PartyNames
	- `string`, trimmed from the input
- Votes
	- `int`, trimmed  and conevrted from the input.
- NumPivots
	- `int`, is the count of times the PartyName[ka] was potentially pivotal in a vote. 
- CoalitionMember
	- This is an array of `bool` handled in an ususual way. A given bit pattern of this represents a voting coalition where for each CoalitionMember[ka] being true means that PartyName[ka] in in the currently evaluated coalition and could potentially be pivotal.
	 - The main loop in the Exhaustive processing option just incremants this by calling `allcoal()`. It is little endian. 
	- It also is one element longer than the others. This is effectively a carry bit, so if it is set you know you iterated through all possible combinations of the lower bits.
	- For Monto Carlo processing, this is a randomly generated on a bit by bit basis.
- BanzIndex
	- `double` by default, is the ratio of NumPivots[a]/TotalPivots and is calculated in the stage `banzcomp`.

## The processing stages
- setFromCommandFlags()
	- Process command line options
- init()
	- Sets up the PRNG from the flags, if necessary.
- readdata()
	- read from stdin, interpreting based on `--informat=` option.
	- output into `np`, `Votes`, `PartyNames`.
	- Header data into `nid`, `IdHeader` if present. therwise nid = 0.
- massage()
	- Not in the original.
	- Calculates values needed by the processing that need only be done once.
	- Does validation and consistency checks where possible.
	- REMOVED Initializes `NumPivots` slots to 0.
		- Moved to declaration.
	- Calculates `totalVotes`, `npp1`
	- If using a proportion to calculate `mwcvote`, compute it here. (turned off)
	- Sets unaminity flag as appropriate.
	- In-place sorts the data by `Votes` descending, this enables a processing shortcut.
		- The sort is very lame. Claims to be a bubble sort, but it isn't. Does appear to have the same time complexity.
		- It is suprisingly annoying to get Phobos to do this, so I just copied the original. I expect that for really large datasets the run time is going to be dominated by the main processing loops.
		- Write or find a better sort later.
- if unaminityFlag then
	- unanimousVote()
- else
	- Either of, based on the `--process=` option.
		- randcomp()
			- Monto Carlo testing.
		- exhaust()
			- Interate through all possible combinations.
- banzcomp()
	- Late stage processing
	- Sum the total pivots from NumPivots
	- Validate totalPivots to avoid a divide by zero.
	- Compute the BanzIndex for each entry.

- banzprint()
	- Output the results to stdout.

## Random Numbers

The Monte Carlo processing needs a decent random number source.
However the original pseudo-random number generator in Apple Pascal
was somewhat weak, generating only uniform unsigned 15 bit Integer
output in [0,32767] from what I vaguely recall was a Park-Miller
PRNG.  The auto seeding was driven off the keyboard input poll, so if
you didn't do any input, the seed was constant.

The internal use of this to generate a random coalition is in two phases:

1. Generate a random number *pMembership*.
2. Iterate over all the parties, generating another random number (*pParty*) for each of then setting the coalition membership to true if *pMembersiip > pParty*. No attempt is made at removing duplicates.

The nice part of this procedure it it enable you to work in integers
without lossy calculations, which was *much* faster on the hardware
then, and less prone to error than the Applesoft Basic ROM floating
point.

Arguably the original PRNG is really too weak for the task at hand,
particularly for a large number of experimental runs. You could get
through 15 bits of cycling numbers in not a lot of time, even then.
But, there wasn't much choice in 1984 on an 8-bit microcomputer. Now,
it is completely inadequate.

I'm doing the same approach here, except with wider integers and a
better PRNG, the Mersenne Twister set to standard parameters MT1997.
32 bits may not be enough, so I've abstracted the PRNG output to
`PrngOutputType` which should be some kind of unsigned integer.  We
are only ever comparing with other random numbers using `<`, so any
changes shouldn't affect the rest of the program.

For repeatability it is going to need an option to select a seed for
the generator. Seeding is fairly straightforward:

- `--seed=123456789`
	- if not present or 0, have the system select a seed arbitrarily.
	- otherwise initialize it from an unpredictable source.
- This will only have an effect if "--process=montecarlo"

The PRNG is held in the global `monteCarloGen` and is invoked by the
function `randomGen()`. The range generated is
[0..PrngOutputType.max] and closed on both ends. This is set up in
`init()`.

I was going to use the Phobos `std.random.uniform()`, but at least
parts of it are `@gc`. Since this is called inside of the loop, this
is unacceptable.  Instead, I'm using a modified verison of the
MT19337 PRNG as implemented in C at
https://github.com/bmurray7/mersenne-twister-examples/ in the file
`c-mersennetwister.c`.  I've wrapped it in a `struct
MersenneTwisterGeneratorU32` to keep it isolated, did some minor
renaming, and declared all of the functions to be `@nogc
nothrow @safe`.  At the moment, the randomize seeding is done by
`std.random.unpredictableSeed()` since outside the loop, GC isn't as
relevant (and a later version of Phobos fixes that).


