defmodule Type.Map do

  @moduledoc """
  Represents map terms.  Note that some of the choices around how to handle
  maps may deviate from the expectations in the typesystem.

  The associated struct has two parameters:
  - `:required` a map of required key types and their associated value types.
  - `:optional` a map of optional key types and their associated value types.

  ### Shortcut Form

  The `Type` module lets you specify a map using "shortcut form" via the
  `Type.map/1` macro:

  Note that the empty map is not the same as `t:map/0`

  ```
  iex> import Type, only: :macros
  iex> type(%{optional(atom()) => pos_integer()})
  %Type.Map{optional: %{%Type{name: :atom} => %Type{name: :pos_integer}}}
  iex> type(%{})       # empty map
  %Type.Map{optional: %{}, required: %{}}
  iex> map()  # t:map/0
  %Type.Map{optional: %{%Type{name: :any} => %Type{name: :any}}}
  ```

  ### Deviations from standard Erlang/Elixir:

  - `Type.Map` only allows literal integers and literal atoms as
    `required` key types.  Typespecs that put other types in as required
    will downgrade those types to be `optional`
  - In the future, this may be extended to ranges.
  - map types will not by default assume `optional(any()) => any()`
  - If multiple specifications exist for the same particular value (for example,
    overlapping ranges in optional keys, or a overlapping types in required vs
    optional), all specifications are applied to that value group.  This may
    result in the map being equivalent to `%Type{name: :none}` but that will
    not automatically be collapsed to that value.

  ### Examples:

  - The empty map is `%Type.Map{}`.  This is not allowed to have any k/v pairs.
    ```
    iex> inspect %Type.Map{}
    "type(%{})"
    ```
  - A map with a required atom key might look as follows:
    ```
    iex> inspect %Type.Map{required: %{foo: %Type{name: :integer}}}
    "type(%{foo: integer()})"
    ```
  - A map with a required integer key might look as follows:
    ```
    iex> inspect %Type.Map{required: %{1 => %Type{name: :integer}}}
    ```
    "type(%{1 => integer()})"
    ```
  - A map with an optional key type might look as follows:
    ```
    iex> inspect %Type.Map{optional: %{%Type{name: :integer} => %Type{name: :integer}}}
    "type(%{optional(integer()) => integer()})"
    ```
  - The "any" map has optional any mapping to any (note this is distinct from empty map `%{}`)
    ```
    iex> inspect %Type.Map{optional: %{%Type{name: :any} => %Type{name: :any}}}
    "map()"
    ```

  ### Key functions:

  #### comparison

  Maps are ordered by required keys, then optional keys.  A map type
  with a required key comes before an equivalent map type with the key optional.

  ```
  iex> import Type, only: :macros
  iex> Type.compare(type(%{foo: :bar}), type(%{foo: :quux}))
  :lt
  iex> Type.compare(type(%{foo: :bar}), type(%{bar: :baz}))
  :gt
  iex> Type.compare(type(%{optional(1) => integer(), foo: integer()}),
  ...>              type(%{optional(2) => integer(), foo: integer()}))
  :lt
  iex> Type.compare(type(%{foo: :bar}), type(%{optional(:foo) => :bar}))
  :lt
  ```

  #### intersection

  If map types cannot support the same required keys, their intersection is `none()`
  If one of the required keys can be created from the pool of the other key's optional types,
  Then it gets realized into the intersection.  Otherwise, the intersection is the
  intersection of key types with key values.  If the optional key or value types are totally
  disjoint, then the intersection is the empty map `%{}` because that term is a member
  of both types

  ```
  iex> import Type, only: :macros
  iex> Type.intersect(type(%{foo: :bar}), type(%{bar: :baz}))
  %Type{name: :none}
  iex> Type.intersect(type(%{foo: :bar}), type(%{optional(atom()) => atom()}))
  %Type.Map{required: %{foo: :bar}}
  iex> Type.intersect(type(%{1 => 1..10}), type(%{1 => 5..20}))
  %Type.Map{required: %{1 => 5..10}}
  iex> Type.intersect(type(%{optional(1..10) => integer()}),
  ...>                   type(%{optional(integer()) => 1..10}))
  %Type.Map{optional: %{1..10 => 1..10}}
  iex> Type.intersect(type(%{optional(1..10) => integer()}),
  ...>                   type(%{optional(1..10) => atom()}))
  %Type.Map{}
  iex> Type.intersect(type(%{optional(1..10) => integer()}),
  ...>                   type(%{optional(11..20) => integer()}))
  %Type.Map{}
  ```

  #### union

  Map unions must be extremely parsimonious, because the specifications on the unions
  are coupled.  Not all combinations of optional and required types can be safely
  subjected to a union.  In general, the union algorithm will merge two types if one
  is a strict subtype of the other.

  ```
  iex> import Type, only: :macros
  iex> Type.union(type(%{foo: :bar}), type(%{}))
  %Type.Map{optional: %{foo: :bar}}
  iex> Type.union(type(%{foo: :bar}), type(%{optional(:foo) => :bar}))
  %Type.Map{optional: %{foo: :bar}}
  iex> Type.union(type(%{foo: 1..10}), type(%{foo: 1..20}))
  %Type.Map{required: %{foo: 1..20}}
  iex> Type.union(type(%{optional(1..10) => 1..10}), type(%{optional(1..20) => 1..10}))
  %Type.Map{optional: %{1..20 => 1..10}}
  ```

  #### subtype?

  A map type is a subtype of the other if all of the keys and values of one are subtypes
  of the other.

  ```
  iex> import Type, only: :macros
  iex> Type.subtype?(type(%{foo: :bar}), type(%{foo: atom()}))
  true
  iex> Type.subtype?(type(%{foo: :bar}), type(%{optional(:foo) => atom()}))
  true
  iex> Type.subtype?(type(%{optional(:foo) => :bar}), type(%{optional(:foo) => atom()}))
  true
  iex> Type.subtype?(type(%{optional(:foo) => :bar}), type(%{foo: atom()}))
  false
  ```

  #### usable_as

  optional keys are maybe usable as required keys; required keys are always usable
  as optional keys.

  for optional keys, if a key type is a subtype of the target's key type, then it is
  maybe usable; if it as a supertype of the target's key type, then it is always usable.

  generally optional types are `:ok` with disjoint key types, but if overlapping key types
  have conflicting value types, then it is `:maybe` because keys must be

  ```
  iex> import Type, only: :macros
  iex> Type.usable_as(type(%{foo: :bar}), type(%{optional(:foo) => :bar}))
  :ok
  iex> Type.usable_as(type(%{optional(:foo) => :bar}), type(%{foo: :bar}))
  {:maybe, [%Type.Message{challenge: %Type.Map{optional: %{foo: :bar}},
                          target: %Type.Map{required: %{foo: :bar}}}]}
  iex> Type.usable_as(type(%{optional(1..10) => 1..10}), type(%{optional(1..20) => 11..20}))
  {:maybe, [%Type.Message{challenge: %Type.Map{optional: %{1..10 => 1..10}},
                          target: %Type.Map{optional: %{1..20 => 11..20}}}]}
  ```

  ## Helper functions

  The docs for helper functions documented here use set theory language,
  treating maps as discrete functions with preimages and images.  This
  page may be of help to understand this language:

  https://en.wikipedia.org/wiki/Image_(mathematics)#Inverse_image

  """

  defstruct [required: %{}, optional: %{}]

  @type required :: %{optional(integer | atom) => Type.t}
  @type optional :: %{optional(Type.t) => Type.t}

  @type t :: %__MODULE__{
    required: required,
    optional: optional
  }

  @type t(key, value) :: %__MODULE__{
    required: %{optional(key) => value},
    optional: %{}}

  @none %Type{name: :none}

  use Type.Helpers

  # compare both
  def compare(%{optional: lopt, required: lreq}, %{optional: ropt, required: rreq})
    when map_size(lopt) > 0 or map_size(ropt) > 0 do

    raise "not supported yet"

    # inverse waterfall with
    with :eq <- compare_keys(lopt, ropt),
         l_postimage = lopt |> Map.values |> Type.union,
         r_postimage = ropt |> Map.values |> Type.union,
         # partition these.
         :eq <- Type.compare(l_postimage, r_postimage),
         :eq <- fewer_keys_gt(lreq, rreq),
         :eq <- compare_keys(lreq, rreq),
         :eq <- compare_images(lreq, rreq) do
      raise "unreachable"
    end
  end

  # case where there are only required literals.  In this situation, we attempt
  # to match the erlang term order, so instead of being a restrictive liability,
  # having more required terms results in a larger map.

  def compare(%{required: lreq}, %{required: rreq}) do
    with {sz, sz} <- {map_size(lreq), map_size(rreq)},
         :eq <- compare_keys(lreq, rreq),
         :eq <- compare_images(lreq, rreq) do
      raise "unreachable"
    else
      {ls, rs} when ls > rs -> :gt
      {_, _} -> :lt
      order -> order
    end
  end

  defp fewer_keys_gt(a, b) do
    case {map_size(a), map_size(b)} do
      {s, s} -> :eq
      {sa, sb} when sa > sb -> :lt
      _ -> :gt
    end
  end

  defp compare_keys(a, b) do
    a_keys = a |> Map.keys |> Enum.sort
    b_keys = b |> Map.keys |> Enum.sort
    compare_typelist(a_keys, b_keys)
  end

  defp compare_images(a, b) do
    compare_typelist(Map.values(a), Map.values(b))
  end

  defp compare_typelist([], []), do: :eq
  defp compare_typelist([lhead | lrest], [rhead | rrest]) do
    case {lhead, rhead} do
      {head, head} -> compare_typelist(lrest, rrest)
      {lhead, rhead} when lhead > rhead -> :gt
      _ -> :lt
    end
  end

  @any %Type{name: :any}
  # if the left and right sides have the *same* required keys AND they are uniformly "bigger"
  # on one side than the other, then we can merge them.
  def merge(left = %{required: lreq = %{}}, right = %{required: rreq = %{}}) when map_size(lreq) == map_size(rreq) do
    if Map.keys(lreq) == Map.keys(rreq) do
      #merge_when_keys_are_same(left, right, lreq, rreq)
      :nomerge
    else
      :nomerge
    end
  end
  def merge(%{optional: %{@any => @any}}, _) do
    {:merge, [%__MODULE__{optional: %{@any => @any}}]}
  end
  def merge(_, _) do
    :nomerge
  end

  def intersect(lmap, rmap = %__MODULE__{}) do
    # find the intersection of the preimages
    preimage_intersection = lmap
    |> preimage
    |> Type.intersect(preimage(rmap))

    # required properties can fail.
    case evaluate_requireds(lmap, rmap, preimage_intersection) do
      {:ok, requireds} ->
        optionals = lmap
        |> evaluate_optionals(rmap)
        |> Map.drop(Map.keys(requireds))
        %__MODULE__{required: requireds, optional: optionals}
      :empty ->
        @none
    end
  end
  def intersect(_, _), do: @none

  defp evaluate_requireds(map, tgt, preimage_intersection) do
    # union the required keys from the map and the target.  This
    # is the full set of required keys from all of the maps.
    all_req_keys = Map.keys(map.required)
    |> Kernel.++(Map.keys(tgt.required))
    |> Enum.uniq

    # check that all required keys exist in the preimage intersection, if
    # it doesn't then we can do an early edit.
    if Enum.all?(all_req_keys, &Type.subtype?(&1, preimage_intersection)) do
      req_kv = all_req_keys
      |> Enum.map(fn rq_key ->
        val_type = map_apply(map, rq_key)
        |> Type.intersect(map_apply(tgt, rq_key))

        val_type == @none && throw :empty

        {rq_key, val_type}
      end)
      |> Enum.into(%{})

      {:ok, req_kv}
    else
      :empty
    end
  catch
    :empty -> :empty
  end

  defp evaluate_optionals(map, tgt) do
    # apply the intersected preimages to the first map.
    # this gives us a list of preimage segments, each of
    # which has a consistent image type.

    map
    |> resegment(resegment(tgt))
    |> Enum.flat_map(fn segment ->
      map
      |> map_apply(segment)
      |> Type.intersect(map_apply(tgt, segment))
      |> case do
        @none -> []
        image -> [{segment, image}]
      end
    end)
    |> Enum.into(%{})
  end

  @doc """
  the full union of all possible key values for the passed map.

  ```elixir
  iex> alias Type.Map
  iex> import Type, only: :macros
  iex> Map.preimage(type(%{pos_integer() => any()}))
  %Type{name: :pos_integer}
  iex> Map.preimage(type(%{0 => any(), pos_integer() => any()}))
  %Type.Union{of: [%Type{name: :pos_integer}, 0]}
  ```
  """
  def preimage(map) do
    map
    |> keytypes
    |> Type.union
  end

  @doc false
  # helper function to get the raw key types out, with no set-theoretic
  # operations performed on them.
  def keytypes(map) do
    Map.keys(map.required) ++ Map.keys(map.optional)
  end

  @doc """
  calculates the image of a map when given a clamping type for the preimage.

  If any part of the clamp doesn't exist in in the map's preimage, it
  is ignored.

  ### Example:

  (note that `0` is in the clamp `-5..5`, but is not in the map preimage)

  ```
  iex> alias Type.Map
  iex> import Type, only: :macros
  iex> Map.apply(type(%{neg_integer() => :foo,
  ...>                 pos_integer() => :bar}), -5..5)
  %Type.Union{of: [:foo, :bar]}
  ```

  If any part of the clamp has conflicting definitions, it is dropped.

  ```
  iex> alias Type.Map
  iex> import Type, only: :macros
  iex> Map.apply(type(%{0..3 => :foo, 4..5 => :bar, 4 => :baz, 5 => :quux}), 0..5)
  :foo
  ```

  If any part of the clamp has a more restrictive definition, all type
  restrictions must apply

  ```
  iex> alias Type.Map
  iex> import Type, only: :macros
  iex> Map.map_apply(type(%{0..3 => 1..10, pos_integer() => 0..5}), 1..3)
  1..5
  ```
  """
  def map_apply(map, singleton) when is_integer(singleton) or is_atom(singleton) do
    # optimization for the singleton case.
    segment_apply(map, singleton)
  end
  def map_apply(map, preimage_clamp) do
    map
    |> resegment([preimage_clamp])
    |> Enum.map(&segment_apply(map, &1))
    |> Type.union
  end

  # finds the image of map under a preimage segment.  Note that
  # this algorithm only works correctly if the segment is a valid
  # preimage segment of the map type, or if it's a singleton.
  defp segment_apply(map, segment) do
    required_image = apply_partial(map.required, segment)
    optional_image = apply_partial(map.optional, segment)
    Type.intersect(required_image ++ optional_image)
  end

  # performs an apply operation on either the required part or the
  # optional part of a map type.  Returns a list of images.  You
  # should perform the union operation *outside* this function
  defp apply_partial(req_or_opt, preimage_subtype) do
    req_or_opt
    |> Enum.flat_map(fn {keytype, valtype} ->
      if Type.intersect(keytype, preimage_subtype) == @none do
        []
      else
        [valtype]
      end
    end)
  end

  @spec resegment(t) :: [Type.t]
  @spec resegment(t, [Type.t]) :: [Type.t]
  @doc """
  Takes a list of (disjoint) preimage types "segments" and splits
  them further in such a way that each segment has a consistent
  single type in the map's image.

  - Discards any preimage subsegments which are not present in the map.
  - Does not validate that passed list of preimages are actually disjoint.
  - No guarantees are made on the order of the resulting list.

  ```elixir
  iex> alias Type.Map
  iex> import Type, only: :macros
  iex> Map.resegment(type(%{neg_integer() => :neg}), [-10..10])
  [-10..-1]
  iex> Map.resegment(type(%{neg_integer() => :neg,
  ...>                     pos_integer() => :pos}), [-10..10])
  [-10..-1, 1..10]
  ```
  """
  def resegment(map, preimages \\ [%Type{name: :any}])
  def resegment(map, [%Type{module: nil, name: :any, params: []}]) do
    Map.keys(map.required) ++ Map.keys(map.optional)
  end
  def resegment(_map, []), do: []
  def resegment(map, [preimage_segment | rest]) do
    import Type, only: :macros

    map
    |> keytypes
    |> Enum.flat_map(fn key_type ->
      case Type.intersect(key_type, preimage_segment) do
        none() -> resegment(map, rest)
        other -> [other | resegment(map, rest)]
      end
    end)
  end

  @spec required_key?(t, atom | integer) :: boolean
  @doc """
  true if the map type specifies a singleton type as one of its required keys
  """
  def required_key?(map, key) when is_atom(key) or is_integer(key) do
    :erlang.is_map_key(key, map.required)
  end
  def required_key?(_, _), do: false

  @doc """
  takes all required terms and makes them optional
  """
  def optionalize(map, opts \\ []) do
    {still_requireds, new_optionals} =
      Map.split(map.required, Keyword.get(opts, :keep, []))

    %Type.Map{optional: Map.merge(map.optional, new_optionals),
              required: still_requireds}
  end

  #  subtype do
  #    def subtype?(challenge, target = %Map{}) do
  #      # check to make sure that all segments are
  #      # subtypes as expected.
  #      segments = Map.resegment(challenge, Map.resegment(target))
#
  #      segment_union = Enum.into(segments, %Type.Union{})
#
  #      # make sure that each part of the challenge is represented
  #      # in the segments
  #      challenge
  #      |> Map.keytypes
  #      |> Enum.all?(&Type.subtype?(&1, segment_union))
  #      |> Kernel.||(throw false)
#
  #      Enum.each(segments, fn segment ->
  #        challenge
  #        |> Map.apply(segment)
  #        |> Type.subtype?(Map.apply(target, segment))
  #        |> Kernel.||(throw false)
  #      end)
  #      # check that all required bits of b are
  #      # required in a.  Note that we already know that
  #      # the subtype situation is valid from the above code.
  #      target.required
  #      |> Elixir.Map.keys
  #      |> Enum.all?(fn key ->
  #        :erlang.is_map_key(key, challenge.required)
  #      end)
  #    catch
  #      false -> false
  #    end
  #  end
#
  #  usable_as do
  #    def usable_as(challenge, target = %Map{}, meta) do
  #      (check_preimages(challenge, target, meta)
  #       ++ check_target_required(challenge, target, meta)
  #       ++ check_challenge_required(challenge, target, meta)
  #       ++ check_challenge_optional(challenge, target, meta))
  #      |> Enum.reduce(:ok, &Type.ternary_and/2)
  #    end
  #  end
#
  #  defp check_preimages(challenge, target, meta) do
  #    challenge_preimage = challenge.optional
  #    |> Elixir.Map.keys
  #    |> Enum.into(%Type.Union{})
#
  #    target_preimage = target.optional
  #    |> Elixir.Map.keys
  #    |> Enum.into(%Type.Union{})
#
  #    is_preimage = Type.intersect(challenge_preimage, target_preimage)
#
  #    if is_preimage == challenge_preimage do
  #      [:ok]
  #    else
  #      [{:maybe, [Message.make(challenge, target, meta)]}]
  #    end
  #  end
#
  #  defp check_target_required(challenge, target, meta) do
  #    # checks that the challenge map can supply all of the required
  #    # keys that the target needs; if they are optional, then it's a
  #    # maybe; in either case the image of the challenger key must be
  #    # usable as the image of the target key.
  #    target.required
  #    |> Enum.map(fn {key, _} ->
  #      target_image = Map.apply(target, key)
  #      challenge_image = Map.apply(challenge, key)
  #      cond do
  #        :erlang.is_map_key(key, challenge.required) ->
  #          Type.usable_as(challenge_image, target_image, meta)
#
  #        challenge_image != none() ->
  #          Type.ternary_and(
  #            {:maybe, [Message.make(challenge, target, meta)]},
  #            Type.usable_as(challenge_image, target_image, meta))
#
  #        true ->
  #          {:error, Message.make(challenge, target, meta)}
  #      end
  #    end)
  #  end
#
  #  defp check_challenge_required(challenge, target, meta) do
  #    challenge.required
  #    |> Enum.map(fn {key, value} ->
  #      cond do
  #        :erlang.is_map_key(key, target.required) ->
  #          Type.usable_as(value, target.required[key], meta)
  #        (target_value = Map.apply(target, key)) != none() ->
  #          Type.usable_as(value, target_value, meta)
  #        true ->
  #          {:error, Message.make(challenge, target, meta)}
  #      end
  #    end)
  #  end
#
  #  defp check_challenge_optional(challenge, target, meta) do
  #    challenge.optional
  #    |> Enum.flat_map(fn {key_type, value_type} ->
  #      target
  #      |> Map.resegment([key_type])
  #      |> Enum.map(&{&1, value_type})
  #    end)
  #    |> Enum.map(fn {segment, value_type} ->
  #      Type.usable_as(value_type, Map.apply(target, segment), meta)
  #    end)
  #    |> Enum.map(fn
  #      {:error, _msg} -> {:maybe, [Message.make(challenge, target, meta)]}
  #      any -> any
  #    end)
  #  end
#
  #  def normalize(%{required: required, optional: optional}) do
  #    {requireds, optionals} = required
  #    |> Enum.map(fn {k, v} -> {Type.normalize(k), Type.normalize(v)} end)
  #    |> Enum.split_with(&(is_atom(elem(&1, 0)) or is_integer(elem(&1, 0))))
#
  #    optionals = optional
  #    |> Enum.map(fn {k, v} -> {Type.normalize(k), Type.normalize(v)} end)
  #    |> Kernel.++(optionals)
  #    |> Enum.into(%{})
#
  #    %Type.Map{required: Enum.into(requireds, %{}), optional: optionals}
  #  end
#
  #end
#
  defimpl Inspect do
    import Inspect.Algebra
    import Type, only: :macros

    @anymap %{any() => any()}

    def inspect(%{required: %{__struct__: atom()}, optional: %{atom() => any()}}, _opts) do
      "struct()"
    end
    def inspect(%{required: %{__struct__: module()}, optional: %{atom() => any()}}, _opts) do
      "struct()"
    end
    def inspect(map = %{required: %{__struct__: struct}}, opts) when is_atom(struct) do
      inner = map.required
      |> Map.from_struct
      |> Enum.reject(&(elem(&1, 1) == Type.any()))
      |> inner_content(opts)

      concat(["type(%#{inspect struct}{", inner, "})"])
    end
    def inspect(%{optional: @anymap}, _opts) do
      "map()"
    end

    def inspect(%{required: required, optional: optional}, opts) do
      concat(["type(%{", inner_content(required, optional, opts), "})"])
    end

    def inner_content(required, optional \\ %{}, opts) do
      requireds = required
      |> Enum.sort
      |> Enum.map(fn
        {src, dst} when is_atom(src) ->
          concat(["#{src}: ", to_doc(dst, opts)])
        {src, dst} ->
          concat([to_doc(src, opts), " => ", to_doc(dst, opts)])
      end)
      optionals = Enum.map(optional, fn {src, dst} ->
        concat(["optional(", to_doc(src, opts), ") => ", to_doc(dst, opts)])
      end)
      concat(Enum.intersperse(optionals ++ requireds, ", "))
    end
  end
end
