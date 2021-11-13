# Deviations: Binaries

## Unicode annotation

the `Type.Binary` type struct includes an annotation `:unicode` which
is a boolean, representing if the type is encoded as unicode.

### Relationship to elixir String type

This annotation is required to properly represent the `t:String.t/0` type,
because according to the documentation, this type must be encoded as
unicode.