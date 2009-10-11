#! /usr/bin/perl
#---------------------------------------------------------------------
# $Id: 00.load.t 2035 2008-06-25 23:41:21Z cjm $
#---------------------------------------------------------------------

use Test::More tests => 1;

BEGIN {
    use_ok('MooseX::AttributeTree');
}

diag("Testing MooseX::AttributeTree $MooseX::AttributeTree::VERSION");
