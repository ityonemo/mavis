# The Mavis Typesystem

The Mavis typesystem features two distinct and unique concepts which were
conceived of as tool specialized for the BEAM virtual machine's type system,
and can be considered a refinement built on top of the type specs that are used
by `dialyzer`, the legacy erlang type-checking system.

- `subtype` roughly corresponds to what you might expect, `A subtype B`
  means that the all elements of type A are subtypes of element B
- `usable_as` emits a ternary logic value in the set {`ok`, `maybe`, `error`}.
  this corresponds to the question:  Will the VM raise on `:badarg` or
  `:function_clause` if you pass the value A into something that expects B.

`usable_as` could be used as compiler guidelines - for example, a `maybe` result
could emit a warning and an `error` result could halt compilation.

In the Mavis Library,

```elixir
use Type.Operators
```

overloads `~>` as `usable_as` and `in` as `subtype_of`

**Be extremely careful!** you should only use `Type.Operators` if you really
know what you're doing.  In the case of Mavis, this is used exclusively to
make tests easier to read.

## `usable_as` examples:

### obvious strict subtypes

- `1 ~> 1` -> `ok`
- `1 ~> 0..6` -> `ok`
- `0..6 ~> integer` -> `ok`
- `pos_integer ~> integer` -> `ok`
- `integer ~> any` -> `ok`

### strict supertypes

- `0..6 ~> 1` -> `maybe`
- `pos_integer ~> 0..6` -> `maybe`
- `any ~> 1` -> `maybe`

### disjoint sets

- `integer ~> atom` -> `error`
- `1 ~> atom` -> `error`
- `any ~> none` -> `error`

### maps

- `%{foo: binary} ~> %{foo: binary, optional(:bar) => 0..6}` -> `ok`:
  Note that it is possible for maps to pass usable_as checking even
  if there isn't an obvious subtyping relationship between the challenge
  type and the target type.

### functions

- `(0..6 -> atom) ~> (0..1 -> atom)` -> `ok`:
  note that you can *use* a function with a more general domain with a
  spec that demands a specific domain.

- `(pos_integer -> pos_integer) ~> (integer -> pos_integer)` -> `maybe`:
  the reverse is not true, there are cases when a more demanding, specific
  function domain can cause a crash when passed as a lambda to something
  expecting a general function.

- `(pos_integer -> pos_integer) ~> (pos_integer -> integer)` -> `ok`:
  ranges have the expected relationship with respect to subtypes.
