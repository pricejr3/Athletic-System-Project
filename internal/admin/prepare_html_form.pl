#!/usr/local/bin/perl

#
# Formats an HTML form
#


while ( $form_file = shift ) {
    print "Processing form $form_file...\n";

    open ( FORM, $form_file );
    open ( FORM_NEW, ">$form_file.new" );

    while ( <FORM> ) { s/(<\s*input.*)(<\s*input)/$1\n$2/i; print FORM_NEW; }

    close ( FORM );
    close ( FORM_NEW );

    rename ( "$form_file.new", $form_file );

    print "Done\n\n";
}
