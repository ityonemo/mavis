# Deviations: Functions

## Top-arity Functions

### Rationale

Top-arity functions represent the "top type" for function of a given arity.
In the Mavis typesystem, the parameters to the function signature
signify "which types may be passed and are guaranteed to not crash the
function.  Accordingly, the type-signature `any() -> any()` represents
a *smaller* population of functions than the type-signature `integer() -> any()`,
as the former type signature represents that all values are guaranteed to
succeed, whereas the later represents that only integers are guaranteed to succeed, a less stringent criterion.

Erlang does have a "top type" for functions, namely the any function, which
is denoted in Elixir as`... -> any()`.  However, it is important to note
that there are cases when it is reasonable to be able to select on an
arity-specific top type.  See the example below.

### Nomenclature

in Mavis, this type is represented as `_, _ -> result_type()`,
where the number of underscores corresponds to the arity of this function
type.

internally, these functions are represented by placing a positive integer
in the `:params` field of the `Type.Function.t` struct.

### Example

```
def my_function(f) when is_function(f, 1) do
  :some_result
end
```

should have signature `(_ -> any()) :: :some_result`.

note that Dialyzer gives this function the signature `(any() -> any()) :: :some_result`, which suggests that a lambda passed to `my_function` must
be able to tolerate any input.  In reality, this function will not crash
if passed, for example `:erlang.byte_size/1` which has a more restrictive
signature.

A truly `any() -> any()` lambda would be for example `IO.inspect/1`.

### Notes

At this point, it doesn't seem to qualify the `any() -> any()` as a fully
qualified "subtype" of the `integer() -> any()`, though that may be
implemented later.

There is no zero-arity top-arity function.

### Normalization to erlang function types

the `:params` field is replaced by a list of `any()` types of the appropriate
arity.  Namely the following happens:

`_ -> any()` to `any() -> any()`
`_, _ -> any()` to `any(), any() -> any()`

when performing type *inference*, any function which is specced to take lambdas
with all `any()` parameters should be viewed with suspicion and subjected to
inference.