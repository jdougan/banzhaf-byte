#
# Quick calculation of total votes and mwc (assuming majority vote)
# to crosscheck banzdemo. Input is a no header tsv file.
#
BEGIN	{FS="\t" ; tot = 0}
	{tot = tot + $2}
END	{
		print "tot=", tot ;
		mwc1 = tot / 2;
		if ((tot - mwc1) >= mwc1) {
			mwc1 = mwc1 + 1;
		}
		print "mwc=", mwc1 ;
	}
