#!/usr/bin/env awk -f
BEGIN {
    if (length(radius) == 0) {
	print "[ERROR] Variable 'radius' must be defined!" > "/dev/stderr";
	exit 1;
    }
    OFS="\t";
}
{
    ## truncate around end (or start) based on strand
    switch($6) {
	case "+":
	    print $1, $3 - radius, $3 + radius, $4, $5, $6;
	    break
	case "-":
	    print $1, $2 - radius, $2 + radius, $4, $5, $6;
	    break
	default:
	    printf "[ERROR] Encountered non-stranded entry on line %d" NR > "/dev/stderr";
	    exit 1;
    }
}
