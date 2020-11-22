# Deviations: Tuples

## Min-size and Pinned Value Tuples

### Rationale

Min-size tuples represent the type of all tuples with a minimum size.
There are some functions which will crash if they don't present with a
tuple of a desired type.  It may also be possible to constrain internal
datatypes, as well.  See the example below.

### Example

the following function

```
def my_function(tup) when elem(tup, 1) == :foo do
  :some_result
end
```

should have signature `{any(), :foo, ...} :: :some_result`.

note that Dialyzer gives this function the signature `tuple() :: :some_result`, which does not serve to indicate that tuples of size 0 and 1 will be rejected.

### Notes

Any tuple with minimum zero should be identical to tuple().

### Normalization to erlang tuple types

Any tuple that does not have a fixed size is converted to `tuple()`.  This
is a very disappointing loss of information.