#---------------------------------------------------------------------
package MooseX::AttributeTree::Accessor;
#
# Copyright 2009 Christopher J. Madsen
#
# Author: Christopher J. Madsen <perl@cjmweb.net>
# Created: October 9, 2009
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# ABSTRACT: Moose accessor role for inheritance through the object tree
#---------------------------------------------------------------------

our $VERSION = '0.03';

use MooseX::Role::Parameterized;

parameter qw(parent_link
  is       ro
  isa      Str
  required 1
);

parameter qw(fetch_method
  is       ro
  isa      Maybe[Str]
  required 1
);

parameter qw(default
  is       ro
  isa      Maybe[Value|CodeRef]
  required 1
);

role {
  my $parent_link  = $_[0]->parent_link;
  my $fetch_method = $_[0]->fetch_method;
  my $default      = $_[0]->default;

  # I haven't created inline versions of the methods yet:
  method 'is_inline' => sub { 0 };

  method '_generate_accessor_method' => sub {
    my $attr = (shift)->associated_attribute;
    my $class = $attr->associated_class;
    my ($method, @args) = $fetch_method
        ? ($fetch_method, $attr->name)
        : ($attr->get_read_method);

    return sub {
      $attr->set_value($_[0], $_[1]) if scalar(@_) == 2;

      if ($attr->has_value($_[0])) {
        return $attr->get_value($_[0]);
      } else {
        my $result;
        if (my $parent = $class->find_attribute_by_name($parent_link)
                               ->get_value($_[0])) {
          $result = $parent->$method(@args);
        } # end if $parent
        return (defined $result ? $result :
                ref $default ? $_[0]->$default : $default);
      } # end else this object has no value for the attribute
    } # end anonymous accessor sub
  }; # end _generate_accessor_method

  method '_generate_reader_method' => sub {
    my $attr = (shift)->associated_attribute;
    my $class = $attr->associated_class;
    my ($method, @args) = $fetch_method
        ? ($fetch_method, $attr->name)
        : ($attr->get_read_method);

    return sub {
      $attr->throw_error('Cannot assign a value to a read-only accessor',
                         data => \@_) if @_ > 1;

      if ($attr->has_value($_[0])) {
        return $attr->get_value($_[0]);
      } else {
        my $result;
        if (my $parent = $class->find_attribute_by_name($parent_link)
                               ->get_value($_[0])) {
          $result = $parent->$method(@args);
        } # end if $parent
        return (defined $result ? $result :
                ref $default ? $_[0]->$default : $default);
      } # end else this object has no value for the attribute
    } # end anonymous reader sub
  }; # end _generate_reader_method

}; # end role

#=====================================================================
# Package Return Value:

1;

__END__

=head1 DESCRIPTION

MooseX::AttributeTree::Accessor is the backend that does the work for
the C<TreeInherit> trait.  See L<MooseX::AttributeTree> for details.

=for Pod::Loom-omit
BUGS AND LIMITATIONS
CONFIGURATION AND ENVIRONMENT
INCOMPATIBILITIES
