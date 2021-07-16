#!/usr/bin/env awk -f

################################################################################
## Purpose: Filters alignments that end in softclip ('S') at 3'-end
##   Input: SAM
##  Output: SAM
################################################################################
{
    ## retain header
    if ($0 ~ /^@/) { print; next }

    ## process reads by strand
    if (and($2, 0x10) == 0) {
	## forward strand (ends with S)
	cigar="^.*[0-9]+M.*[0-9]+S$";
    } else {
	## reverse strand (starts with S)
	cigar="^[0-9]+S.*[0-9]+M.*$";
    }
    if ($6 ~ cigar) { print }
}
