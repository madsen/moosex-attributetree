MooseX::AttributeTree - Inherit attribute values like HTML+CSS does
-------------------------------------------------------------------

SYNOPSIS
========

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

DESCRIPTION
===========

Classes can inherit attributes from their parent classes.  But
sometimes you want an attribute to be able to inherit its value from a
parent object.  For example, that's how CSS styles work in HTML.

MooseX::AttributeTree allows you to apply the `TreeInherit` trait to
any attribute in your class.  This changes the way the attribute's
accessor method works.  When reading the attribute's value, if no
value has been set for the attribute in this object, the accessor will
return the value from the parent object (which might itself be
inherited).

The parent object does not need to be the same type as the child
object, but it must have a method with the same name as the
attribute's accessor method.  (The parent's method may be an attribute
accessor method, but it doesn't have to be.)  If the parent doesn't
have the right method, you'll get a runtime error if the child tries
to call it.
