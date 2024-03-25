// banzdemo.d
/*
	Ported from banzdemo in pascal from Byte Magazine, March 1983.
	writeln(' BANZHAF INDEX DEMONSTRATION PROGRAM');
	writeln(' (c) 1983, Philip A. Schrodt');
*/
@safe

// ============================================================
// Consts and Vars

enum EXIT_NOERROR = 0;
enum EXIT_BADFORMATHEADER = 1;
enum EXIT_BADFORMATVOTES = 2;
enum EXIT_UNKNOWNFORMAT = 3;
enum EXIT_NOPIVOTS = 4;


// The source uses pascal arrays counting from 1, I have lots of
// memory, just add one to the top end so I can pretend it is one
// indexeed
// Original wa 200
enum MAXVOTES = 200 + 1;

// Original was 10
// This stsrts from 0 to MAXIDLINES - 1.
enum MAXIDLINES = 50 ; 


string[MAXVOTES] PartyNames;
int[MAXVOTES] Votes;
int[MAXVOTES] NumPivots;
string[MAXIDLINES] IdHeader;
// CoalitionMember is treated as a MAX votes + 1 integer
// a true bit means the coresponding party in in the coalition
// the extra ib ia the carry bit, if it is true you are past the valid range
bool[MAXVOTES+1] CoalitionMember;
double[MAXVOTES] BanzIndex;

// number of coalitions evaluated;
// total pivots, 
// number of header lines,
// number of parties,
// votes required for mwc
int  ncex , totpivots , nid, np , mwcvote ;

// Assorted counters, some of these should be moved into thw corresponding functions.
// total votes = sum(Votes)
// number 
int  totvot, nex , kz, ka, kb , npp1 ;

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
	all
}
ProcessingType shouldProcessExhaustively ;

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

// ============================================================
//  Procedures
// 

@safe int setFromCommandFlags(ref string[] args){
	import std.getopt;
	import std.stdio;
	// banzdemo --process=all --mwc=51  --informat=bytemag --header=all < votes.txt > results.txt
	// --process=montecarlo --process=all
	// --mwc=567
	// --informat=bytemag --informat=tab --informat=csv
	// --header==all --header=none --header=column

	// --mecp=1/5
	// --seed=653567864543
	// --mwcfrac=1/2 

	mwcvote = 0;
	shouldOutputHeader = OutputHeaderGenerated.all;
	shouldProcessExhaustively = ProcessingType.all;
	inputFormatExpected = InputFormat.bytemag;
	// FIXME would it make sense to optionally use a percentage for mwc?
	// should default to 1/2
	mwcProportionNumerator = 0;
	mwcProportionDenominator = 0;
	// mwcvote = 51; 

	auto aparse = getopt(args,
		"mwc" , &mwcvote,
		"header", &shouldOutputHeader,
		"informat", &inputFormatExpected,
		"process", &shouldProcessExhaustively,
		);

	return EXIT_NOERROR;
}


@nogc nothrow @safe void init() {
	for(int ka = 1; ka < MAXVOTES; ka ++ ) {
		NumPivots[ka] = 0;
	}
}

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
		debugPrint!(1,"Start of Header Parse",true)("");
		while (scanningHeader) {
			string rawLine = readln();
			size_t len = rawLine.length;
			if (len == 0) {
				// early end of file, incorrect file
				return (EXIT_BADFORMATHEADER);
			} else if (len == 1) {
				// end of the header
				scanningHeader = false;
			} else {
				if (nid == MAXIDLINES) {
					return (EXIT_BADFORMATHEADER);
				}
				IdHeader[nid] = rawLine[0..$-1];
				debugPrint!(1,"==>",true)(IdHeader[nid]);
				nid = nid + 1;
			}
		}
		debugPrint!(1,"End of Header Parse",true)("");

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
				debugPrint!(1,"==>", false)(rawLine);
				size_t sepIndex = rawLine.indexOf(':');
				if (sepIndex == -1) {
					// No seperator, line oif ill formed.
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
		debugPrint!(1,"End of Body Parse, count ",true)(to!string(np));
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


@nogc nothrow @safe int sortdata_orig() {
	// Copy of the sort from the Pascal original. Claimed to be a
	// bubblesort. Not really a bubblesort though I think it has the
	// same time complexity.
	int tmpi; 
	string tmps;

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
//string tmps;
//int tmpi;

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

@nogc nothrow @safe void massage(){
	nex = 0;
	for(int ka = 1; ka <= np; ka++){
		nex = nex + Votes[ka];
	}
	npp1 = np + 1;
	if (mwcvote == 0) {
		// if it is zero, then it needs to be calculated from porportions.
		// in not zero, we assume it is good.
		// Probably should be cecked to endure that it if in [1,np]
		assert(mwcProportionNumerator > 0);
		assert(mwcProportionDenominator > 0);
		uint votesToPass = (nex * mwcProportionNumerator) / mwcProportionDenominator;
		uint remainderToPass = (nex * mwcProportionNumerator) % mwcProportionDenominator;
		// FIXME probably not right
		mwcvote = votesToPass + 1;
	}
	sortdata_orig();
}



@nogc nothrow @safe void exhaust() {
	// Taken from the original Pascal program, this is essentially
	// counting up with the binary number represented by the bit array
	// CoalitionMember. You could probably do it with an array of
	// unsigned, at some complexity cost. CoalitionMember[np+1] is
	// the "carry" bit and it being set is the sign that you have
	// reached the end.
	ncex = 0;
	for (ka = 1; ka <= npp1; ka ++) {
		CoalitionMember[ka] = false;
	}
	do {
		ncex++;
		allcoal();
		countpivots();
	} while (!(CoalitionMember[npp1]));
}

@nogc nothrow @safe void randcomp() {
	// FIXME
	assert(0, "Monte Carlo not yet impleented.");
}

@nogc nothrow @safe void allcoal() {
	//(* this increments the mem array to get the next coalition.
	//Cycles through all coalitions by treating ' mem' as though it were
	//a sequence of binary numbers 1 to 2 ^np -- "allcoal " in effect does
	//a binary add of "i" to "mem" *)
	int bitNum = 1;
	CoalitionMember[bitNum] = !(CoalitionMember[bitNum]);
	while( !(CoalitionMember[bitNum]) ) {
		bitNum ++;
		CoalitionMember[bitNum] = !(CoalitionMember[bitNum]);
	}
}

@nogc nothrow @safe void countpivots() {
	//var totvot , ka:integer;
	//begin
	//	totvot:=O;
	//	for ka := 1 to np do if mem[ka] then totvot := totvot+votes[ka];
	//	if totvot >= mwcvote then begin
	//		for ka: =1 to np do
	//			if mem[ka] then
	//				if (totvot - votes[ka]) < mwcvote then
	//					numpivots[ka]:= numpivots[ka]+1
	//				else
	//					ka := np; (*note: this shortcut assumes sorted votes...*)
	//	end;
	//end;
	// FIXME not ocmplete yet
	int totalVote, ka ;
	totalVote = 0;
	for (ka = 1; ka <= np; ka++ )  {
		if (CoalitionMember[ka]) {
			totalVote = totalVote + Votes[ka];
		}
	}
	if (totalVote >= mwcvote) {
		for (ka = 1; ka <= np; ka ++) {
			if(CoalitionMember[ka]) {
				if ((totalVote - Votes[ka]) < mwcvote) {
					NumPivots[ka]++;
				} else {
					// with this trick work in D?
					/// allegedly this magic only works if sorted, not sure why
					ka = np;
				}
			}
		}
	}
}


@nogc nothrow @safe int banzcomp() {
	int ka;
	totpivots = 0;
	for (ka = 1; ka <= np; ka ++) {
		totpivots = totpivots + NumPivots[ka];
	}
	if (totpivots == 0) {
		return EXIT_NOPIVOTS;
	}
	for (ka = 1; ka <= np; ka ++) {
		BanzIndex[ka] = (cast(double)NumPivots[ka]) / (cast(double)totpivots);
	}
	return EXIT_NOERROR;
}


// The output is a tab delimited file, with eoln being \n
// colums are party name, voltes, banzhaf index
// Not the approach from the source as we are trying to make it Unix tools friendly
//
@trusted void banzprint() {
	import std.stdio;
	import std.conv;

	if (shouldOutputHeader == OutputHeaderGenerated.all) {
		debugPrint!(1, "Header line count: \t", true)(to!string(nid));
		for (ka = 0; ka < nid; ka++) {
			writeln(IdHeader[ka]);
		}
		static if (StaticVerbosity >= 1) {
			writeln("mwcvote\t",mwcvote);
			writeln("nex\t",nex);
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
		double voteProp = (Votes[ka] / cast(double)nex);
		write(PartyNames[ka], "\t", Votes[ka], "\t", voteProp, "\t");
		write( NumPivots[ka], "\t", BanzIndex[ka], "\t", (BanzIndex[ka] - voteProp), "\t", (BanzIndex[ka] / voteProp),"\n");
	}
}


@safe int main(string[] args) {
	int err = 0;
	err = setFromCommandFlags(args);
	if (err != EXIT_NOERROR) {
		return err;
	}
	init();
	err = readdata();
	if (err != EXIT_NOERROR) {
		return err;
	}
	massage();
	final switch (shouldProcessExhaustively) {
		case ProcessingType.montecarlo:
			randcomp();
			break;
		case ProcessingType.all: 
			exhaust();
			break;
	}
	err = banzcomp();
	if (err != EXIT_NOERROR) {
		return err;
	}
	banzprint();
	return EXIT_NOERROR;
}
