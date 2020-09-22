# The Mavis Typesystem

## General coercion

`coerces(a, b)` means:

if you attempt to use any value of type `a` in a place where type `b` is
expected, then the following are the responses:

- `:type_ok` all things in type `a` satisfy type `b`
- `:type_maybe` there is at least one thing in type `a` which satisfies type `b`;
  there is also at least one thing in type `a` which does not satisfy type `b`.
- `:type_error` nothing in type `a` satisfies type `b`

### Examples

  `neg_integer` into `integer` -> `:type_ok`
  `integer` into `pos_integer` -> `:type_maybe`
  `neg_integer` into `pos_integer` -> `:type_error`

## With functions

### Parameters

given a function of type

```text
neg_integer -> any
```

in a situation where we expect

```text
integer -> any
```

then we're in trouble because if we take an `f` that satisfies the first
parameter and we use it in the second parameter, we could get a type error
when we pass `10` into `f`.

conversely if we consider

```text
integer -> any
```

and pass into a situation where we expect

```text
neg_integer -> any
```

then this will always work.

### Return values

given a function of type

```text
any -> integer
```

in a situation where we expect

```text
any -> pos_integer
```

then we're in trouble because if we take an `f` that satisfies the first
parameter and we use it in the second parameter, we could get a type error
if `-1` is returned.

conversely if we consider

```text
any -> pos_integer
```

and pass into a situation where we expect

```text
any -> integer
```

then this will always satisfy the requirements.
