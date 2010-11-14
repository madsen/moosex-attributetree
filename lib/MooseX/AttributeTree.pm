#---------------------------------------------------------------------
package MooseX::AttributeTree;
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
# ABSTRACT: Inherit attribute values like HTML+CSS does
#---------------------------------------------------------------------

our $VERSION = '0.03';

=head1 DEPENDENCIES

MooseX::AttributeTree depends on
{{$t->dependency_link('MooseX::Role::Parameterized')}}, which
can be found on CPAN.

=cut

use MooseX::Role::Parameterized;

use MooseX::AttributeTree::Accessor ();

=attr parent_link

This is the name of the attribute which links to the object's parent.
The default is C<parent>.

=attr fetch_method

This is the name of the method to call in the parent object to ask for
the value of an attribute.  The method is passed the name of this
attribute as its sole argument.  This allows attributes to be
inherited without requiring the parent object to know about every
possible attribute.

If C<fetch_method> is not set, then the parent's value is fetched by
calling the method with the same name as the attribute's read accessor
method.  In that case, no parameters are passed to the parent method.

=attr default

This attribute will provide the default value for the inherited
attribute when no value has been set on this object and no value could
be inherited from the parent.  It has the same semantics as Moose's
standard C<default> option, in that it can be either a Value or a
CodeRef to call as a method on the object with no parameters.

The difference is that the default value is not stored in the object.
If you provide a CodeRef, it will be called I<every time> the default
value is needed.

=cut

parameter qw(parent_link
  is      ro
  isa     Str
  default parent
);

parameter qw(fetch_method
  is      ro
  isa     Str
);

parameter qw(default
  is      ro
  isa     Maybe[Value|CodeRef]
);

# Hook accessor_metaclass to apply the MooseX::AttributeTree::Accessor role:
role {
  my $parent_link  = $_[0]->parent_link;
  my $fetch_method = $_[0]->fetch_method;
  my $default      = $_[0]->default;

  around accessor_metaclass => sub {
    my $orig = shift;
    my $self = shift;

    return Moose::Meta::Class->create_anon_class(
      superclasses => [ $self->$orig(@_) ],
      roles => [ 'MooseX::AttributeTree::Accessor',
                 { parent_link  => $parent_link,
                   fetch_method => $fetch_method,
                   default      => $default } ],
      cache => 1
    )->name
  };
};

# Register this trait as TreeInherit:
{
  package Moose::Meta::Attribute::Custom::Trait::TreeInherit;
  sub register_implementation {'MooseX::AttributeTree'}
}

#=====================================================================
# Package Return Value:

1;

__END__

=head1 SYNOPSIS

  package MyClass;
  use Moose;
  use MooseX::AttributeTree ();

  has parent => (
    is       => 'rw',
    isa      => 'Object',
    weak_ref => 1,
  );

  has value => (
    is     => 'rw',
    traits => [qw/TreeInherit/],
  );

=head1 DESCRIPTION

Classes can inherit attributes from their parent classes.  But
sometimes you want an attribute to be able to inherit its value from a
parent object.  For example, that's how CSS styles work in HTML.

MooseX::AttributeTree allows you to apply the C<TreeInherit> trait to
any attribute in your class.  This changes the way the attribute's
accessor method works.  When reading the attribute's value, if no
value has been set for the attribute in this object, the accessor will
return the value from the parent object (which might itself be
inherited).

The parent object does not need to be the same type as the child
object, but it must have a method with the same name as the
attribute's accessor method (unless you supply a C<fetch_method>).
(The parent's method may be an attribute
accessor method, but it doesn't have to be.)  If the parent doesn't
have the right method, you'll get a runtime error if the child tries
to call it.

By default, MooseX::AttributeTree expects the link to the parent
object to be stored in the C<parent> attribute.  However, you can use
any attribute as the link by passing the appropriate C<parent_link> to
the C<TreeInherit> trait:

  has ancestor => (
    is       => 'rw',
    isa      => 'Object',
    weak_ref => 1,
  );

  has value => (
    is     => 'ro',
    traits => [ TreeInherit => { parent_link => 'ancestor' } ],
  );

If the parent attribute is not set (or is undef), then inheritance
stops and the accessor will behave like a normal accessor.

Sometimes it's not convenient for the parent object to have a separate
method for each attribute that a child object might want to inherit.
In that case, you can supply a C<fetch_method> to the C<TreeInherit>
trait.

  has other_value => (
    is     => 'ro',
    traits => [ TreeInherit => { fetch_method => 'get_inherited' } ],
  );

With C<fetch_method>, the inherited value will come from

  $self->parent->get_inherited('other_value');

instead of the usual

  $self->parent->other_value();

If your attribute has a predicate method, it reports whether the
attribute has been set on that object.  The predicate has no knowledge
of any value that might be inherited from a parent.  This means that
C<< $object->has_value >> may return false even though
C<< $object->value >> would return a value (inherited from the parent).

Likewise, the attribute's clearer method (if any) would clear the
attribute only on this object, and would never affect a parent object.

=head1 BUGS AND LIMITATIONS

There is no inline version of the accessor methods, so using the
TreeInherit trait will slow down access to that attribute.  But in
practice, it hasn't been slow enough to be noticeable.

No attempt is made to detect circular dependencies, which may cause
an infinite loop.  (This should not be an issue in a proper tree
structure, which should not have circular dependencies.)

If an accessor returns C<undef>, there's no way to tell whether no
ancestor had the attribute set, or one of them explicitly set it to
C<undef>.  (Well, you could walk the inheritance tree yourself and
call the predicate method of each ancestor.)

=for Pod::Loom-insert_after
AUTHOR
ACKNOWLEDGMENTS

=head1 ACKNOWLEDGMENTS

I'd like to thank Jesse Luehrs, who explained what I needed to do to
get this module to work, and Micro Technology Services, Inc.
L<http://www.mitsi.com>, who sponsored its development.
