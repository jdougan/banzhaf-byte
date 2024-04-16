(* Banzhaf.p *)
PROGRAM BANZDEMO;
(* program for computing Banzhaf indices using Monte-Carlo simulation
	or exhaustive evaluation.
	Apple II Pascal *)
(*$C copyright ( C) 1983 , Philip A. Schrodt *)

uses applestuff;
	(* Two procedures used from applestuff:
	randomize : randomly set seed of random number generator
	random : function generating random numbers with a
	Uniform[0,1] distribution *)

const maxvot = 200; (* maximum number of partys allowed *)

var 
	votes : array[1..maxvot ] of integer ; (*votes by party*)
	ncex , totpivots , nid,np , mwcvote:integer ; (* number of coalitions evaluated;
		total pivots,number of id lines,
		number of parties,votes required for mwc*)
	numpivots : array [l .. maxvot] of integer ; (*number of pivots*)
	name: array [1 .. maxvot] of string; (* party names *)
	id: array [1 .. 10] of string; (* run identification information*)
	mem: array[1 .. 201] of boolean ; (*coalition membership*)
		(* Warning : change 201 to maxvot + l if maxvot is changed *)
	bi: array [1 .. maxvot] of real; (* Banzhaf indices*)
	printflag : boolean;
	totvot,nex , kz,ka,kb , npp1: integer ;(* assorted counters *)
	inf,pr: text ; (* input file , printer*)
	sta:string;

procedure banzprint ; forward;

function answer ( S:string ): boolean;
	(* writes question S and checks for 'Y' answer *)
	var C:char;
	begin
		write ( S,'? -->');
		read(C);
		writeln;
		(* chr(27) is ESC key*)
		if C=Chr(27) then Exit (program);
		answer := ((C='Y') or (C='y'))
	end;

function iconv(S:string):integer;
	(* converts string S into integer, ignoring all chars except numerals,
	and '-'. No error checking.
	Warning- this is an extraordinarily forgiving integer input procedure...*)
	var i,p,k:integer;
		neg:boolean;
	begin
		i:=O;
		neg := false;
		for k := 1 to Length(S) do begin
			p:=ord(S1k]);
			if (p<58) and (p>47) then
				i:=i*10 + (p-48)
			else if p=45 then
				neg := true;
		end;
		if neg then iconv := -i else iconv:=i;
	end;

procedure sortfile;
	(* bubble sort ' name ' and 'votes' by votes *)
	(* this was slow in the before time, so it write to show it is working.*)
	(* looks like it wants to sort ascending *)
	var ka,kb,kc:integer;
		sta:string;
	begin
		write('Sorting data');
		for ka := 1 to np-1 do
			begin
				write('.');
				for kb := ka to np do
					if votes[kb] > votes[ka] then (* votes[ka] < votes[kb' *)
						begin
							sta := name[ka];
							name[ka] := name[kb];
							nam[kb] := sta;

							kc := votes[ka];
							votes[ka] := votes[kb];
							votes[kb] := kc;
						end;
			end;
		writeln();
	end;

procedure readstring(s:string; var n:string; var v:integer);
	(* breaks out the party (n)ame and (v)otes from input string *)
	(* line format is "nameStr:votesNumber*)
	(* Avoid a party named error*)
	var ka:integer;
	begin
		ka := pos(':',s);
		if ka = O then
			begin
				(* No colon in the line, is error*)
				n := 'error';
				v := O;
				exit(readstring);
			end;
		n := copy(s,1,ka-1);
		if ka=length(s) then
			(* if blank, assume zero vites. Shoudn't change results *)
			v := 0
		else
			v := iconv(copy(s,ka+l,length(s)-ka));
	end;

function readstringxxx(s:string; var n:string; var v:integer) integer;
	(* breaks out the party (n)ame and (v)otes from input string *)
	(* line format is "nameStr:votesNumber*)
	(* Avoid a party named error*)
	var ka:integer;
	begin
		ka := pos(':',s);
		if ka = O then
			begin
				(* No colon in the line, is error*)
				readstringxxx := -1;
				n = 'error';
				v := O;
				(* exit(readstring); *)
			end;
		else 
			begin
				n := copy(s,1,ka-1);
				if ka = length(s) then
					(* if blank, assume zero votes. Shoudn't change the results *)
					v := 0
				else
					v := iconv(copy(s,ka+l,length(s)-ka));
				readstringxxx := 0;
			end;
	end;

procedure readdata;
	(*read vote data *)
	var ka , kb : integer;
		sta : string;

	procedure readfile;
		(* read from a file *)
		begin
			write('Enter file name-->'); readln(sta);
			if (pos ('.text', eta)=O ) and (pos ('.TEXT',eta)-O) then
				sta := concat (sta,'.TEXT');
			reset (i of , sta) ;
			(* read file identification info *)
			nid := O;
			repeat
				nid:=nid+1;
				readln ( inf,id[nid]);
				writeln ( id[nid]);
			until ( length ( idCnid] )=O) or (nid=10);
			if nid= 1O then begin
				writeln (' Sorry, maximum of ten lines allowed...');
				repeat readln ( inf,sta ) until length ( sta)=O;end
			else nid:=nid-1;
			(* read vote data *)
			readln(inf,sta);
			ka:=0;
			while (not eof(inf)) and (length(sta)>O) and (ka<=maxvot) do begin
				kas-ka+l;writeln(sta);
				readstring( sta,nameCka ],votes[ka]);
				readln(inf,sta);
			end;
			if ka>=maxvot then writeln ('Read stopped at ',maxvot,' parties');
				close(inf);
		end; (* readfile *)

	procedure read2;
		(* tail-end of READDATA procedure , which is otherwise too long *)
		begin
			nex:=O;
			for ka :=1 to np do nex:=nex+votes[ka];
			writeln('Total votes entered: ', nex);
			write('Enter number of votes of minimum winning coalitions');
			readln(mwcvote);
			sortfile;
		end;
	begin
		if answer('Is vote data on a TEXT file')
		then readfile
		else begin (* read from keyboard *)
			writeln('Enter identification info (null to stop)s');
			nid:=O;
			repeat
				nid:=nid+1;
				readln(idtnid])
			until (length(idtnid])=O) or (nid=1O);
			if nid=1O then writeln('Sorry, maximum of ten lines allowed...')
			else nids=nid-1;
			writeln('Enter party id and number of votes separated');
			writeln(' by : for each party; null record to finish');
			ka := O;
			repeat
				readln(sta);
				if length(sta)>O then begin
					ka:=ka+1;
					readstring( sta,nametka ],voteslka]);
					if votestka]<O then begin
						kas=ka-2;
						writeln ('Sackspace -- next entry will replace');
						writeln(' ',nametka ],' : ', votestka]);
					end;
				end;
			until (length(sta)=O) or (ka-maxvot);
			if ka=maxvot then writeln(' Maximum of ',maxvot,' parties allowed');
		end;
		np:=ka; npp1:=np+1;
		read2;
	end; (* readdata *)

procedure init; (* initializes assorted parameters *)
	begin 
		randomize();
		for ka := 1 to maxvot do
			numpivots[ka]:= O;
	end;

procedure randcoal;
	(*creates a random coalition and counts pivots*)
	var pr , ka:integer;
	begin 
		pr := random();
		for ka := 1 to np do
			mem[ka] := (random() < pr);
	end;

procedure allcoal;
	(* this increments the mem array to get the next coalition.
	Cycles through all coalitions by treating ' mem' as though it were
	a sequence of binary numbers 1 to 2 ^np -- "allcoal " in effect does
	a binary add of "i" to "mem" *)
	var ka : integer;
	begin 
		ka:=1; 
		mem[ka] := (not mem[ka]);
		while not mem[ka] do begin
			ka := ka + 1;
			mem[ka] := (not mem[ka]); 
		end;
	end;

procedure countpivot;
	(* determines the pivotal members in the current coalition
	and increments numpivot array *)
	var totvot , ka:integer;
	begin
		totvot:=O;
		for ka := 1 to np do
			if mem[ka ] then
				totvot := totvot+votes[ka];
		if totvot >= mwcvote then
		begin
			for ka: =1 to np do
				if mem[ka ] then
					if (totvot - votes[ka]) < mwcvote then
						numpivots[ka] := numpivots[ka] + 1
					else
						ka := np (*note: this shortcut assumes sorted votes...*)
		end;
	end;

procedure exhaust;
	(* evaluation of Banzhaf indices by computing all coalitions *)
	var ka:integer;
	begin 
		ncex:=O;
		for ka := 1 to npp1 do mem[ka] := false;
		repeat 
			ncex := ncex + l;
			allcoal();
			countpivots();
			if (ncex mod 20 ) = O then write('.');
		until mem[np+1];
		(* stop when np+ 1 element of mem is 'true' *)
	end;

procedure randcomp;
	(* evaluates Banzhaf indices using Monte-Carlo methods *)
	var ka:integer;
	begin
		write (' Enter number of random coalitions to generate:');
		readln(sta);
		next=iconv(sta);
		writeln (' A "." is printed for each 20 coalitions');
		for ka: = 1 to nex do begin
			randcoal;
			countpivots;
			if (ka mod 20 )=O then begin
				write('.');
				if (ka mod 500 )=O then
					writeln (' Total coalitions:', ka);
			end;
			ncex:=nex;
		end;
	end;

procedure banzcomp;
	(* computes Banzhaf indices*)
	var ka:integer;
	begin
		totpivots:=O;
		for ka:=1 to np do totpivots:=totpivots+numpivots[ka];
		if totpivots=O then begin
			writeln ('Error -- no pivots recorded');
			exit(banzprint);
		end;
		for ka:=1 to np do bi[ka] := numpivots[ka]/totpivots;
	end;

procedure print ( st:string);
	begin
		writeln(st);
		if printflag then writeln ( pr,st);
	end;

procedure banzprint;
	(* computes and prints results *)
	var ka:integer;
		sta,stb,sty:string;

	procedure printres ;(* prints individual results *)
		var rato,dif , prop:real;
		begin
			for ka := 1 to np do begin
				prop :=votesCka] /totvot;dif :=bi[ka]-prop ; rato:=bi(ka ]/prop;
				stb:=copy ( concat ( name(ka], ' '),1,10);
				write ( stb,' ',votes(ka]: 5,' ',prop : 8:5,' ',bi(ka ]: 8:5);
				writeln (' ', dif:8 : 5,' ',rato:8:5, ' ',stb);
				if (not printflag ) and ((ka mod 20 )=O) then begin
					writeln (' <PRESS RETURN>');
					readln(sta);
					writeln ( sty);
				end;
				if printflag then begin
					write ( pr,stb ,' ', votes(ka ]: 5,' ',prop : 8:5,' ',bi(ka]:8:5);
					writeln ( pr,' ',dif:8 : 5,' ',rato:8: 5,' ',stb);
				end(* if *);
			end ;
		end (*printres*);

	begin  (*banzprint*)
		writeln;
		printflag :=answer (' Do you want hard copy');
		if printflag then rewrite ( pr,'printer:');
		print(' ');
		for ka := 1 to nid do print ( id(ka]);
		print(' ');
		str(mwcvote,sta);
		print ( concat (' Votes for minimum winning coalition= ',sta));
		str(ncex,sta);
		print ( concat (' Total Experiments= ', sta));
		banzcomp;
		str(totpivots,sta);
		print ( concat (' Total Pivots= ', sta));
		print(' ');
		totvot := O; for ka:=1 to np do totvot := totvot + votes(ka];
		sty:='NAME VOTES PROP VT BANZHAF DIFF RATIO NAME';
		print(sty);
		printres();
		if printflag then close(pr);
	end; (* banzprint *)


begin (* main program *)
	write(chr(12)); (* clear screen *)
	writeln(' BANZHAF INDEX DEMONSTRATION PROGRAM');
	writeln(' (c) 1983, Philip A. Schrodt');
	writeln;
	repeat
		init();
		readdata();
		writeln();
		writeln(' Enter Y for exhaustive evaluation,');
		if answer(' N for Monte-Carlo evaluation ') then exhaust() else randcomp();
		banzprint();
		writeln();
	until ( not answer (' Do you wish to compute additional indices'))
end (* main program *) .














