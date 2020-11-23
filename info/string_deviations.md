# Deviations: Strings

## Size-tagged strings

### Rationale

Size-tagged strings are string types which memoize the byte length of
the string.  These are necessary because Elixir's `t:String.t/0` type
drops the byte length of the string, which could be useful information
for the compiler.

Unions of size-tagged strings are subjected to concatenation into ranges
and unions.

### Example

```
Type.of("foo") # ==> String.t(3)
```

### Normalization to elixir String type

The integer type parameter is stripped and converted to the empty list []

In the future, this may be changed to be the `non_neg_integer()` type