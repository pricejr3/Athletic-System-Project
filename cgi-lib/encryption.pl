# encryption.pl
#
# Copyright 1999, Melampus Enterprises, Inc.
# Author: Michael Duff
# Last modified: March 30, 1999
#
# Description: Encryption and checksum utilities


use Digest::MD5 qw(md5_hex);


sub compute_hash
{
    return md5_hex (shift);
}


1;
