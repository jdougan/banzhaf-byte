(*
Copy of the sorting section of banzdemo.p with OCR errors fixed.
This is so I can make sure I understand it as it isn't actually
the usual bubble sort.

Adjusted fot the Online Pascal Compiler at 
    https://www.onlinegdb.com/.
*)
program SortingTest;

var
	np: integer; 
	votes: array [1..10] of integer;
	swaps : integer;
    
    
procedure setup() ;
    begin
        votes[1] := 5;
        votes[2] := 1;
        votes[3] := 4;
        votes[4] := 2;
        votes[5] := 3;
        np := 5;
        swaps := 0
    end;

procedure sortfile();
	(* ?bubblesort? ' 'votes' by votes *)
	(* This isn't really bubblesort, but that is what the banzdemo
	called it. this was slow in the before time, so the write is
	to show it is working. It sorts descending *)

	var ka, kb, kc: integer;

	begin
		write('Sorting data');
		swaps := 0;
		for ka := 1 to np-1 do
			begin
				write('.');
				for kb := ka to np do
				    { If v_ka less than v_kb then out of order }
					if votes[kb] > votes[ka] then (* votes[ka] < votes[kb' *)
						begin
							swaps := swaps + 1;
							kc := votes[ka];
							votes[ka] := votes[kb];
							votes[kb] := kc;
						end;
			end;
		writeln();
	end;

procedure print();
   var ka: integer;
   begin
        write('Swaps=');
        writeln(swaps);
        write('np=');
        writeln(np);
        for ka := 1 to np do begin
            writeln(votes[ka])
        end
    end;

begin
  writeln('=====Sorting Test =========');
  setup();
  sortfile();
  print();
  writeln('===========================')
end.