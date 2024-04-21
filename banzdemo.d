// banzdemo.d
/*
	Ported from banzdemo in pascal from Byte Magazine, March 1983.
	writeln(' BANZHAF INDEX DEMONSTRATION PROGRAM');
	writeln(' (c) 1983, Philip A. Schrodt');
*/
@safe

import std.random : unpredictableSeed ;

// ============================================================
// Consts and Vars

enum EXIT_NOERROR = 0;
enum EXIT_BADFORMATHEADER = 1;
enum EXIT_BADFORMATVOTES = 2;
enum EXIT_UNKNOWNFORMAT = 3;
enum EXIT_NOPIVOTS = 4;
enum EXIT_BADARGS = 5;
enum EXIT_INCONSISTENTDATA = 6;


// The source uses pascal arrays counting from 1, I have lots of
// memory, just add one to the top end so I can pretend it is one
// indexeed
// Original wa 200
enum MAXVOTES = 200 + 1;

// Original was 10
// This stsrts from 0 to MAXIDLINES - 1.
enum MAXIDLINES = 50 ; 

alias FloatT = double;

/// Pseudo Random Generator config
/// uint is always 32 bits
alias PrngOutputType = uint  ;

PrngOutputType seed = 0;

int[MAXVOTES] Votes = 0;;
int[MAXVOTES] NumPivots = 0;
string[MAXVOTES] PartyNames;
string[MAXIDLINES] IdHeader;
/++
CoalitionMember is treated as an unsigned integer with a width of
(NumParties + 1) bits, a true bit means the coresponding party is in
the coalition.  The extra bit ia the carry bit, if it is true you are
past the valid range. In theory, it might be faser to pack it into
bits instead of the byte default to reduce cache pressure..
+/
bool[MAXVOTES+1] CoalitionMember = false;
FloatT[MAXVOTES] BanzIndex = 0.0;

/// number of coalitions evaluated, running number of experiments
/// Used for status output, when I readd it.
int ncex;

/// total pivots, 
int totpivots;

/// number of header lines,
int nid;

/// Number of Parties,
int np;

/// Cache of Number of Parties + 1
int npp1 ;

/// votes required for mwc (Minimum Winning Coalition)
int mwcvote ;

/// total votes = sum(Votes)
int totalVotes;

/// iindicates we are in the unanimity special case
/// where we can shortcut the calculations
bool unanimityFlag = false;

/// Number of Experiments: number of Monte Carlo runs..
/// 2 ** 20
int nex =1_048_576;

// Assorted  counters, might be removeable.
// int kz, ka, kb;


/// Error message to accompany error returns.
string errString;

// ============================================================
// flags to be set from command line

enum InputFormat : int {
	// the format used in the original byte article with header and
	// colon separator
	bytemag, 
	// single tab delimited, first 2 couloms are columns are assumed
	// party and votes, remainder of columns ignored. Optional cilumn
	// headers.
	tab,
	// CSV, first 2 columns are assumed to be party and votes.
	// Optional column headers.
	csv, 
};
InputFormat inputFormatExpected;
// If true, skip the first line in formates that can have a column
// header.
bool expectInputColumnHeader; 
// Proportion of voltes you must have to win a wote. Implementation so
// far is kinda iffy.
uint mwcProportionNumerator = 0;
uint mwcProportionDenominator = 0;

enum ProcessingType {
	montecarlo,
	all,
}
ProcessingType howToProcess ;

enum OutputHeaderGenerated {
	none,
	columns,
	all
}
OutputHeaderGenerated shouldOutputHeader;

// ============================================================
// First atempt at a static debug printet that will compile out to
// nothing
// if Static venbosty == 0, no level >= 0 should log
// if stati verbosity is 1, 
// level should aleays be [0,+inf]
// if SV is 0, then print nothing
enum StaticVerbosity = 0;
@trusted void debugPrint(int level = 1, string prefix = "", bool eoln = false)(string datum){
	import std.stdio;
	static if (StaticVerbosity >= level) {
		stderr.write(prefix,datum);
		static if (eoln) {
			stderr.writeln();
		}
	}
}


/++
A port of the c-mersennetwister.c rng at
https://github.com/bmurray7/mersenne-twister-examples/ . I've wrapped
its state in a struct and moved all the support into the struct as
well.
+/
struct MersenneTwisterGeneratorU32 {
	// #include <stdint.h>
	alias uint32_t = uint;
	alias uint16_t = ushort;

	/// Define MT19937 constants (32-bit RNG)
	enum
	{
	    // Assumes W = 32 (omitting this)
	    N = 624,
	    M = 397,
	    R = 31,
	    A = 0x9908B0DF,

	    F = 1812433253,

	    U = 11,
	    // Assumes D = 0xFFFFFFFF (omitting this)

	    S = 7,
	    B = 0x9D2C5680,

	    T = 15,
	    C = 0xEFC60000,

	    L = 18,

	    MASK_LOWER = (1UL << R) - 1,
	    MASK_UPPER = (1UL << R)
	};

	///
	uint32_t[N] mt;

	///
	uint16_t index;

	/// Re-init with a given seed
	void initialize(const uint32_t  seed) @nogc nothrow @safe
	{
	    uint32_t  i;
	    mt[0] = seed;
	    for ( i = 1; i < N; i++ )
	    {
	        mt[i] = (F * (mt[i - 1] ^ (mt[i - 1] >> 30)) + i);
	    }
	    index = N;
	}

	/// Interal function to mix the data.
	void twist() @nogc nothrow @safe
	{
	    uint32_t  i, x, xA;
	    for ( i = 0; i < N; i++ )
	    {
	        x = (mt[i] & MASK_UPPER) + (mt[(i + 1) % N] & MASK_LOWER);
	        xA = x >> 1;
	        if ( x & 0x1 )
	            xA ^= A;
	        mt[i] = mt[(i + M) % N] ^ xA;
	    }
	    index = 0;
	}

	/// Obtain a 32-bit random number
	uint32_t extractU32() @nogc nothrow @safe
	{
	    uint32_t  y;
	    int       i = index;
	    if ( index >= N )
	    {
	        twist();
	        i = index;
	    }
	    y = mt[i];
	    index = cast(uint16_t)(i + 1);
	    y ^= (y >> U);
	    y ^= (y << S) & B;
	    y ^= (y << T) & C;
	    y ^= (y >> L);
	    return y;
	}


}

PrngOutputType randomGen() @nogc nothrow @safe {
	return monteCarloGen.extractU32();
}

MersenneTwisterGeneratorU32 monteCarloGen;

// ============================================================
//  Procedures
// 

int setFromCommandFlags(ref string[] args) @safe {
	import std.getopt;
	// banzdemo --process=all --mwc=51  --informat=bytemag --header=all < votes.txt > results.txt
	// --process=montecarlo --process=all
	// --mwc=567
	// --informat=bytemag --informat=tab --informat=csv
	// --header==all --header=none --header=column
	// --nex=1224 - Number of expoerments run. if monto caro this is a request.

	// --mecp=1/5
	// --seed=653567864543
	// --mwcfrac=1/2 

	mwcvote = -1;
	// nex = 1_048_576;
	shouldOutputHeader = OutputHeaderGenerated.all;
	howToProcess = ProcessingType.all;
	inputFormatExpected = InputFormat.bytemag;
	// FIXME would it make sense to optionally use a percentage for mwc?
	// should default to 1/2
	mwcProportionNumerator = 0;
	mwcProportionDenominator = 0;

	GetoptResult aparse;
	try {
		aparse = getopt(args,
			config.required,
			"mwc" , &mwcvote,
			config.passThrough,
			"process", &howToProcess,
		);
	} catch (GetOptException ex) {
		errString = "--mwc required";
		return EXIT_BADARGS;
	}
	aparse = getopt(args,
		config.passThrough,
		"header", &shouldOutputHeader,
		"informat", &inputFormatExpected,
		"nex", &nex,
		"seed", &seed,
		);
	return EXIT_NOERROR;
}

/++
Early  initialization. Can throw and be @gc.
+/
void init() @safe {
	// Might make sense to move all this to massage()?
	ncex = 0;
	final switch (howToProcess) {
		case ProcessingType.all:
			break;
		case ProcessingType.montecarlo:
			if (seed == 0) {
				// FIXME need to find non Phobos seeding source 
				monteCarloGen.initialize(unpredictableSeed());
			} else {
				monteCarloGen.initialize(seed);
			}
			break;
	}
}


/++
Read the data from stdin. Changes process based in --informat swittch
expressed in the inputFormatExpected var. Error handling on bad
format is either Exit Code, or  crash with an assertion failure.
+/
@safe int readdata() {

	@trusted int readbytedata() {
		import std.stdio;
		import std.string;
		import std.conv;

		// for now we are going to do the format he used in the BYTE
		// article 1 to MAXIDLINES lines of header, followed by a
		// blank line followed by name:votes pairs one per line
		// spearated by a colon, followef by the end of the file or a
		// blank line later this should have the option of a tab
		// delimited file in >= 2 columns without the useful
		// descriptoive header
		//
		nid = 0;
		bool scanningHeader = true;
		debugPrint!(2,"Start of Header Parse",true)("");
		while (scanningHeader) {
			string rawLine = readln();
			size_t len = rawLine.length;
			if (len == 0) {
				// early end of file, incorrect file
				errString = "Early end of file in header. Incorrect file?";
				return (EXIT_BADFORMATHEADER);
			} else if (len == 1) {
				// end of the header
				scanningHeader = false;
			} else {
				if (nid == MAXIDLINES) {
					errString = "Header too large.";
					return (EXIT_BADFORMATHEADER);
				}
				IdHeader[nid] = rawLine[0..$-1];
				debugPrint!(2,"==>",true)(IdHeader[nid]);
				nid = nid + 1;
			}
		}
		debugPrint!(2,"End of Header Parse",true)("");

		np = 0 ;
		bool scanningBody = true;
		while (scanningBody) {
			string rawLine = readln();
			size_t len = rawLine.length;
			if ((len == 0) || (len == 1)) {
				// Correct End is either EOF or empty line
				scanningBody = false;
			} else {
				// should check for overflow here
				debugPrint!(2,"==>", false)(rawLine);
				size_t sepIndex = rawLine.indexOf(':');
				if (sepIndex == -1) {
					// No seperator, line oif ill formed.
					errString = "Separator (:) missing in votes.";
					return EXIT_BADFORMATVOTES;
				} else {
					string partyName = rawLine[0..sepIndex];
					string partyVotes = rawLine[sepIndex+1..$-1];
					debugPrint!(2,"N==>", true)(partyName);
					debugPrint!(2,"V==>", true)(partyVotes);
					PartyNames[np + 1] = strip(partyName); 
					Votes[np + 1] = to!int(strip(partyVotes)); 
				}
				np = np + 1;
			}
		}
		debugPrint!(2,"End of Body Parse, count ",true)(to!string(np));
		return EXIT_NOERROR;
	}

	@trusted int readtabdelimited() {
		import std.stdio;
		import std.string;
		import std.conv;
		import std.regex;

		bool finished = false;
		uint currIndex = 0;
		auto splitPattern = regex(r"\t|\n");

		while(!finished) {
			string rawLine = readln();
			// has newline at end
			size_t len = rawLine.length;
			if ((len == 0) || (len == 1)) {
				// Correct End is either EOF or empty line
				finished = true;
			} else {
				currIndex = currIndex + 1;
				string[] fields = split(rawLine,splitPattern);
				if(fields.length < 2) {
					errString = "Fewer than 2 fields in record in tab delimited file.";
					return EXIT_BADFORMATVOTES;
				}
				PartyNames[currIndex] = strip(fields[0]);
				Votes[currIndex] = to!int(strip(fields[1]));
			}
		}
		np = currIndex;
		return EXIT_NOERROR;
	}

	@trusted int readcsv() {
		import std.csv;
		assert(0,"CSV Parser Not Yet Written.");
		return EXIT_NOERROR;
	}

	final switch(inputFormatExpected) {
		case InputFormat.bytemag:
			return readbytedata();
			break;
		case InputFormat.tab:
			return readtabdelimited();
			break;
		case InputFormat.csv:
			return readcsv();
			break;
	}
}

/**
Copy of the sort from the Pascal original. Claimed to be a bubblesort.
Not really a bubblesort though I think it has the same time
complexity.
*/
@nogc nothrow @safe int sortdata_orig() {

	int tmpi; 
	string tmps;
	int ka, kb;

	for(ka = 1; ka <= (np - 1); ka++) {
		for(kb = ka; kb <= np ; kb++) {
			// Ordering contraint (Votes[ka] >= Votes[kb] for ka < kb
			if (Votes[kb] > Votes[ka]) { 
				tmps = PartyNames[ka];
				PartyNames[ka] = PartyNames[kb];
				PartyNames[kb] = tmps;

				tmpi = Votes[ka];
				Votes[ka] = Votes[kb];
				Votes[kb] = tmpi;
			}
		}
	}
	return EXIT_NOERROR;
}


// =================================================================
// Sorting
// used in th swap function. in global for improved locality.
// string tmps;
// int tmpi;

//@safe @nogc void myswap(int ka, int kb) nothrow {
//	// could replace with system swap? FIXME check.
//	tmps = PartyNames[ka];
//	PartyNames[ka] = PartyNames[kb];
//	PartyNames[kb] = tmps;

//	tmpi = Votes[ka];
//	Votes[ka] = Votes[kb];
//	Votes[kb] = tmpi;
//}

//@safe @nogc bool mylessthan(int ka, int kb) nothrow {
//	return Votes[ka] > Votes[kb];
//}

//@safe @nogc int sortdata() {
//	import ceres.sorting ;

//	uint swaps = bubbleSortFn!(int, myswap,mylessthan)(1, np);
//	return EXIT_NOERROR;
//}

//====================================================================

/++
Calculates values from the read data that need only be done
once. Data consistency checking should go here.
+/
int massage() @nogc nothrow @safe {
	// No longer needed, initialization are now on the declaration.
	// for(int ka = 1; ka < MAXVOTES; ka ++ ) { NumPivots[ka] = 0; }
	totalVotes = 0;
	for(int ka = 1; ka <= np; ka++){
		totalVotes = totalVotes + Votes[ka];
	}

	// FIXME shoud we check the individual viotes for z/positivity
	// here or in readdata?

	if(totalVotes <= 0) {
		errString = "totalVotes <= 0, probably bad data.";
		return EXIT_INCONSISTENTDATA;
	}

	npp1 = np + 1;
	if (false) {
	//if (mwcvote < 1) {
		// if it is less than one, it is impossible, then it needs to be
		// calculated from proportions. in 1 or more, we assume it is good.
		// Probably should be checked to ensure that it is in [1,np]
		// for now, just crash with a meaningful error message.
		assert(0, "mwc proportion calculation unimplemented.");
		assert(mwcProportionNumerator > 0);
		assert(mwcProportionDenominator > 0);
		uint votesToPass = (totalVotes * mwcProportionNumerator) / mwcProportionDenominator;
		uint remainderToPass = (totalVotes * mwcProportionNumerator) % mwcProportionDenominator;
		// FIXME probably not right
		mwcvote = votesToPass + 1;
	}

	if(mwcvote < 0){
		errString = "mwc votes is less than 1.";
		return EXIT_INCONSISTENTDATA;
	}
	if(mwcvote > totalVotes){
		errString = "mwc votes > total votes.";
		return EXIT_INCONSISTENTDATA;
	}
	if(mwcvote == totalVotes) {
		// special case, we can shortcut the calculation and save a lot of time.
		unanimityFlag = true;
	}
	sortdata_orig();
	return EXIT_NOERROR;
}

/++
For the current configuation of CoalitionMember, count all the pivotal
votes in NumPivots[]..
+/
@nogc nothrow @safe void countpivots() {
	//var totvot , ka:integer;
	//begin
	//	totvot:=O;
	//	for ka := 1 to np do
	//		if mem[ka] then totvot := totvot+votes[ka];
	//	if totvot >= mwcvote then begin
	//		for ka :=1 to np do
	//			if mem[ka] then
	//				if (totvot - votes[ka]) < mwcvote then
	//					numpivots[ka]:= numpivots[ka]+1
	//				else
	//					ka := np; (*note: this shortcut assumes sorted votes...*)
	//	end;
	//end;

	/// Total votes th the current coalition
	int coalitionVotes ;

	int ka ;
	coalitionVotes = 0;
	for(ka = 1; ka <= np; ka++ )  {
		if (CoalitionMember[ka]) {
			coalitionVotes = coalitionVotes + Votes[ka];
		}
	}
	if(coalitionVotes >= mwcvote) {
		for(ka = 1; ka <= np; ka ++) {
			if(CoalitionMember[ka]) {
				if((coalitionVotes - Votes[ka]) < mwcvote) {
					NumPivots[ka]++;
				} else {
					/+ 
					We skip to the next coalition when the number of
					party votes gets small enough that changing
					their votes doesn't matter.  Since sorted
					descending, all the later ones are equal in
					size or smaller, so are in the same position.
					Done like this probably because Pascal has
					none of  return, continue,  or break.
					+/
					// ka = np;
					return;
				}
			}
		}
	}
}

/**
this increments the CoalitionMember array to get the next coalition.
Cycles through all coalitions by treating CoalitionMember as though
it were a sequence of binary numbers [1, 2^np] "allcoal" in effect
does a binary add of "1" to "CoalitionMember".
*/
@nogc nothrow @safe void allcoal() {
	int bitNum = 1;
	CoalitionMember[bitNum] = !(CoalitionMember[bitNum]);
	while( !(CoalitionMember[bitNum]) ) {
		bitNum ++;
		CoalitionMember[bitNum] = !(CoalitionMember[bitNum]);
	}
}

/**
Taken from the original Pascal program, this is essentially
 counting up with the binary number represented by the bit
 array CoalitionMember. You could probably do it with an array
 of unsigned, at some complexity cost. CoalitionMember[np+1] is
 the "carry" bit and it being set is the sign that you have
 reached the end.
*/
void exhaust() @nogc nothrow @safe
{
/*	void dump(){
		import std.stdio;
		writeln(CoalitionMember[1..npp1 + 2]);
	}
*/
	int ka;
	ncex = 0;

	// decl init should have sone this.
	/*for (ka = 1; ka <= npp1; ka ++) {
		CoalitionMember[ka] = false;
	}*/
	do {
		ncex++;
		//dump();
		allcoal();
		countpivots();
	} while (!(CoalitionMember[npp1]));
}


/**
Set CoalitionMember to a randomly generated coalition.
*/
void randcoal() @safe @nogc nothrow {
	size_t ka;
	PrngOutputType pMembership = randomGen();
	for(ka = 1; ka <= np; ka ++){
		CoalitionMember[ka] = randomGen() < pMembership ;
	}
}


/**
nex times, pick a random coalition ads count the pivots.
*/
void randcomp() @nogc nothrow @safe  {
	int ka;

	// Validate nex here , should be set from switches
	assert(nex > 0, "Number of experiments (--nex) should be > 0.");
	for (ka = 1; ka <= nex; ka ++){
		randcoal();
		countpivots();
		ncex++;
		// FIXME this is in original code, should it be outside the
		// loop?
		// ncex = nex;
	}
}


/++
Handle the special case where in the case of unanimity is required,
(mwcvotes == totalVotes) there is only one case that will generate
pivots. Set that up, count the pivots and we are done.
+/
void unanimousVote() @nogc nothrow @safe {
	CoalitionMember = true;
	CoalitionMember[npp1] = false;
	countpivots();
	ncex++;
}


/**
After the main processing, sum the core results before printing.
*/
@nogc nothrow @safe int banzcomp() {
	int ka;
	totpivots = 0;
	for (ka = 1; ka <= np; ka ++) {
		totpivots = totpivots + NumPivots[ka];
	}
	if (totpivots == 0) {
		// Avoids an upcoming divide by zero
		errString = "Total pivot count is 0, cannot proceed.";
		return EXIT_NOPIVOTS;
	}
	for (ka = 1; ka <= np; ka ++) {
		BanzIndex[ka] = (cast(FloatT)NumPivots[ka]) / (cast(FloatT)totpivots);
	}
	return EXIT_NOERROR;
}


/**
 The output is a tab delimited file, with eoln being \n. Columns are
 party name, voltes, banzhaf index, etc. Not the approach from the
 source as we are trying to make it Unix tools friendly.
*/
@trusted void banzprint() {
	import std.stdio;
	import std.conv;

	int ka, kb;

	if (shouldOutputHeader == OutputHeaderGenerated.all) {
		debugPrint!(1, "Header line count: \t", true)(to!string(nid));
		for (ka = 0; ka < nid; ka++) {
			writeln(IdHeader[ka]);
		}
		static if (StaticVerbosity >= 1) {
			writeln("mwcvote\t",mwcvote);
			writeln("totalVotes\t",totalVotes);
			writeln("nex\t",nex);
			writeln("ncex\t",ncex);
			writeln("totpivots\t",totpivots);
		}
		writeln();
	}
	debugPrint!(1, "Body line count: \t", true)(to!string(np));
	if (shouldOutputHeader == OutputHeaderGenerated.columns || shouldOutputHeader == OutputHeaderGenerated.all) {
		write("PartyName\tVotes\tVoteProp\t");
		writeln("NumPivots\tBanzIndex\tBI-VP\tBI/VP");
	}
	for (ka = 1; ka <= np; ka ++) {
		FloatT voteProp = (Votes[ka] / cast(FloatT)totalVotes);
		write(PartyNames[ka], "\t", Votes[ka], "\t", voteProp, "\t");
		write( NumPivots[ka], "\t", BanzIndex[ka], "\t", (BanzIndex[ka] - voteProp), "\t", (BanzIndex[ka] / voteProp),"\n");
	}
}

/// del function to check data tyoes
@trusted void dumpTechData() {
	import std.stdio : writeln , stderr ;
	stderr.writeln("", typeof(CoalitionMember).sizeof);
}

/// del function to check data tyoes
@trusted void dumpError() {
	import std.stdio : writeln , stderr ;
	stderr.writeln("Error: ", errString);
}



/**
Main: 
*/
@safe int main(string[] args) {
	//dumpTechData();
	int err = 0;
	err = setFromCommandFlags(args);
	if (err != EXIT_NOERROR) {
		dumpError();
		return err;
	}

	init();
	err = readdata();
	if (err != EXIT_NOERROR) {
		dumpError();
		return err;
	}

	err = massage();
	if (err != EXIT_NOERROR) {
		dumpError();
		return err;
	}

	if(unanimityFlag) {
		unanimousVote();
	} else {
		final switch (howToProcess) {
			case ProcessingType.montecarlo:
				randcomp();
				break;
			case ProcessingType.all: 
				exhaust();
				break;
		}
	}
	err = banzcomp();
	if (err != EXIT_NOERROR) {
		dumpError();
		return err;
	}

	banzprint();
	return EXIT_NOERROR;
}
