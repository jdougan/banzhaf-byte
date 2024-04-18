#!/bin/awk
#
# Extract the party and votes columns.
# Input is a no header tsv file.
#
BEGIN	{FS="\t" ; OFS="\t"}
	{print $1 , $2 ;}
