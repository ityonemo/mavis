# Changelog

## 0.0.6
- deprecates `Type.builtin/1` and switches to macros for each type.
- renames `Type.select_builtin/1` to `Type.builtin/1` which can serve
  as bridging functionality.
- changes union behaviour to ignore `t:none()`, with an opt-in for
  explicitness
- fixes `c:Type.Inference.Api.infer/3`
- adds merging behaviour for bitstrings and functions
- adds essays on deviations from erlang and Elixir
- adds `Type.normalize/1` which takes deviations and conforms them to
  dialyzer forms.
- removes inferred field on `t:Type.Function.t/0`.

## 0.0.5
- deprecate `Type.Union.of/2`, use `Type.union/2` instead
- change `non_neg_integer()` from a true builtin to an aliased builtin.
- change `integer()` from a true builtin to an aliased builtin
- adds `Type.map/1`, `Type.tuple/1`, and `Type.function/1` macros
- adds `Type.is_singleton/1` guard
- fixes tuple union merging rules and makes function union merging rules
- adds `top-arity function` for `t:Type.Function.t`
- changes how `t:Type.Tuple.t/1` works, by introducing minimum arity tuples
- makes inspecting types that could be confused as native terms less precarious
  by using parallelism with `Type` module macros.
- overhaul of how union merging works

## 0.0.4
- make `Type.fetch_type/3` use a sane call pattern

## 0.0.3
- support for types of multiply-specced functions
- support for composed type module pipelines
- doc improvements contributed by @mbuhot and @kianmeng

## 0.0.2

some touchup:
- remove lambda examples from tests
- add better support for aliased/composite builtins
- better intro documentation
- support for fictional `String.t/1` type; this will
  probably be pulled out into a plugin in the future.

## 0.0.1

initial push, with full functionality across most of elixir standard library
