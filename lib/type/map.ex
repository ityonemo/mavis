defmodule Type.Map do
  defstruct [required: %{}, optional: %{}]

  import Type, only: :macros

  @type required :: %{optional(integer | atom) => Type.t}
  @type optional :: %{optional(Type.t) => Type.t}

  @type t :: %__MODULE__{
    required: required,
    optional: optional
  }

  @spec build(required :: required, optional :: optional) :: t
  def build(required \\ %{}, optional) do
    %__MODULE__{
      required: required,
      optional: to_map(optional)
    }
  end

  defp to_map(lst) when is_list(lst), do: Enum.into(lst, %{})
  defp to_map(map), do: map

  @doc """
  the full union of all possible key values for the passed map.

  ```elixir
  iex> alias Type.Map
  iex> import Type
  iex> Map.preimage(Map.build(%{builtin(:integer) => builtin(:any)}))
  %Type{name: :integer}
  iex> Map.preimage(Map.build(%{0 => builtin(:any)},
  ...>                        %{builtin(:pos_integer) => builtin(:any)}))
  %Type{name: :non_neg_integer}
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
  iex> import Type
  iex> Map.apply(Map.build(%{builtin(:neg_integer) => :foo,
  ...>                       builtin(:pos_integer) => :bar}), -5..5)
  %Type.Union{of: [:foo, :bar]}
  ```

  If any part of the clamp has conflicting definitions, it is dropped.

  ```
  iex> alias Type.Map
  iex> import Type
  iex> Map.apply(Map.build(%{0..3 => :foo, 4..5 => :bar, 4 => :baz, 5 => :quux}), 0..5)
  :foo
  ```

  If any part of the clamp has a more restrictive definition, all type
  restrictions must apply

  ```
  iex> alias Type.Map
  iex> import Type
  iex> Map.apply(Map.build(%{0..3 => 1..10, builtin(:pos_integer) => 0..5}), 1..3)
  1..5
  ```
  """
  def apply(map, singleton) when is_integer(singleton) or is_atom(singleton) do
    # optimization for the singleton case.
    segment_apply(map, singleton)
  end
  def apply(map, preimage_clamp) do
    map
    |> resegment([preimage_clamp])
    |> Enum.map(&segment_apply(map, &1))
    |> Enum.reject(&(&1 == builtin(:none)))
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
  # should perfrom the union operation *outside* this function
  defp apply_partial(req_or_opt, preimage_subtype) do
    import Type, only: [builtin: 1]
    req_or_opt
    |> Enum.flat_map(fn {keytype, valtype}->
      if Type.intersection(keytype, preimage_subtype) == builtin(:none) do
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
  iex> import Type
  iex> Map.resegment(Map.build(%{builtin(:neg_integer) => :neg}), [-10..10])
  [-10..-1]
  iex> Map.resegment(Map.build(%{builtin(:neg_integer) => :neg,
  ...>                           builtin(:pos_integer) => :pos}), [-10..10])
  [-10..-1, 1..10]
  ```
  """
  def resegment(map, preimages \\ [%Type{name: :any}])
  def resegment(map, [%Type{module: nil, name: :any, params: []}]) do
    Map.keys(map.required) ++ Map.keys(map.optional)
  end
  def resegment(_map, []), do: []
  def resegment(map, [preimage_segment | rest]) do
    import Type, only: [builtin: 1]

    map
    |> keytypes
    |> Enum.flat_map(fn key_type ->
      case Type.intersection(key_type, preimage_segment) do
        builtin(:none) -> resegment(map, rest)
        other -> [other | resegment(map, rest)]
      end
    end)
  end

  def required_key?(map, key) do
    :erlang.is_map_key(key, map.required)
  end

  # takes all required terms and makes them optional
  def optionalize(map) do
    build(Map.merge(map.optional, map.required))
  end

  defimpl Type.Properties do

    import Type, only: :macros
    alias Type.{Map, Message}

    use Type

    ##############################################################
    ## comparison

    def group_compare(m1, m2) do
      preimage_cmp = Type.compare(Map.preimage(m1), Map.preimage(m2))
      cond do
        preimage_cmp != :eq -> preimage_cmp
        :eq ->
          m1
          |> Map.resegment(Map.resegment(m2))
          |> Enum.each(fn segment ->
            req_order = required_ordering(m1, m2, segment)
            req_order != :eq && throw req_order

            val_order = Type.compare(Map.apply(m1, segment), Map.apply(m2, segment))
            val_order != :eq && throw val_order
          end)
      end
    catch
      valtype when valtype in [:gt, :lt] -> valtype
    end

    defp required_ordering(m1, m2, segment) do
      case {Map.required_key?(m1, segment), Map.required_key?(m2, segment)} do
        {false, true} -> :gt
        {true, false} -> :lt
        _ -> :eq
      end
    end

    intersection do
      def intersection(map, tgt = %Map{}) do
        # find the intersection of the preimages
        preimage_intersection = map
        |> Map.preimage
        |> Type.intersection(Map.preimage(tgt))

        # required properties can fail.
        case evaluate_requireds(map, tgt, preimage_intersection) do
          {:ok, requireds} ->
            optionals = map
            |> evaluate_optionals(tgt)
            |> Elixir.Map.drop(Elixir.Map.keys(requireds))
            # TODO: ^^ remove the above line when Map.build does this
            # step for you.

            Map.build(requireds, optionals)
          :empty ->
            builtin(:none)
        end
      end
    end

    defp evaluate_requireds(map, tgt, preimage_intersection) do
      # union the required keys from the map and the target.  This
      # is the full set of required keys from all of the maps.
      all_req_keys = Elixir.Map.keys(map.required)
      |> Kernel.++(Elixir.Map.keys(tgt.required))
      |> Enum.uniq

      # check that all required keys exist in the preimage intersection, if
      # it doesn't then we can do an early eiit.
      if Enum.all?(all_req_keys, &Type.subtype?(&1, preimage_intersection)) do
        req_kv = all_req_keys
        |> Enum.map(fn rq_key ->
          val_type = Map.apply(map, rq_key)
          |> Type.intersection(Map.apply(tgt, rq_key))

          val_type == builtin(:none) && throw :empty

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
      |> Map.resegment(Map.resegment(tgt))
      |> Enum.flat_map(fn segment ->
        map
        |> Map.apply(segment)
        |> Type.intersection(Map.apply(tgt, segment))
        |> case do
          builtin(:none) -> []
          image -> [{segment, image}]
        end
      end)
      |> Enum.into(%{})
    end

    def subtype?(_, builtin(:any)), do: true
    def subtype?(challenge, target = %Map{}) do
      # check to make sure that all segments are
      # subtypes as expected.
      segments = Map.resegment(challenge, Map.resegment(target))

      segment_union = Enum.into(segments, %Type.Union{})

      # make sure that each part of the challenge is represented
      # in the segments
      challenge
      |> Map.keytypes
      |> Enum.all?(&Type.subtype?(&1, segment_union))
      |> Kernel.||(throw false)

      Enum.each(segments, fn segment ->
        challenge
        |> Map.apply(segment)
        |> Type.subtype?(Map.apply(target, segment))
        |> Kernel.||(throw false)
      end)
      # check that all required bits of b are
      # required in a.  Note that we already know that
      # the subset situation is valid from the above code.
      target.required
      |> Elixir.Map.keys
      |> Enum.all?(fn key ->
        :erlang.is_map_key(key, challenge.required)
      end)
    catch
      false -> false
    end
    def subtype?(_, _), do: false

    usable_as do
      def usable_as(challenge, target = %Map{}, meta) do
        (check_preimages(challenge, target, meta)
         ++ check_target_required(challenge, target, meta)
         ++ check_challenge_required(challenge, target, meta)
         ++ check_challenge_optional(challenge, target, meta))
        |> Enum.reduce(:ok, &Type.ternary_and/2)
      end
    end

    defp check_preimages(challenge, target, meta) do
      challenge_preimage = challenge.optional
      |> Elixir.Map.keys
      |> Enum.into(%Type.Union{})

      target_preimage = target.optional
      |> Elixir.Map.keys
      |> Enum.into(%Type.Union{})

      is_preimage = Type.intersection(challenge_preimage, target_preimage)

      if is_preimage == challenge_preimage do
        [:ok]
      else
        [{:maybe, [Message.make(challenge, target, meta)]}]
      end
    end

    defp check_target_required(challenge, target, meta) do
      # checks that the challenge map can supply all of the required
      # keys that the target needs; if they are optional, then it's a
      # maybe; in either case the image of the challenger key must be
      # usable as the image of the target key.
      target.required
      |> Enum.map(fn {key, _} ->
        target_image = Map.apply(target, key)
        challenge_image = Map.apply(challenge, key)
        cond do
          :erlang.is_map_key(key, challenge.required) ->
            Type.usable_as(challenge_image, target_image, meta)

          challenge_image != builtin(:none) ->
            Type.ternary_and(
              {:maybe, [Message.make(challenge, target, meta)]},
              Type.usable_as(challenge_image, target_image, meta))

          true ->
            {:error, Message.make(challenge, target, meta)}
        end
      end)
    end

    defp check_challenge_required(challenge, target, meta) do
      challenge.required
      |> Enum.map(fn {key, value} ->
        cond do
          :erlang.is_map_key(key, target.required) ->
            Type.usable_as(value, target.required[key], meta)
          (target_value = Map.apply(target, key)) != builtin(:none) ->
            Type.usable_as(value, target_value, meta)
          true ->
            {:error, Message.make(challenge, target, meta)}
        end
      end)
    end

    defp check_challenge_optional(challenge, target, meta) do
      challenge.optional
      |> Enum.flat_map(fn {key_type, value_type} ->
        target
        |> Map.resegment([key_type])
        |> Enum.map(&{&1, value_type})
      end)
      |> Enum.map(fn {segment, value_type} ->
        Type.usable_as(value_type, Map.apply(target, segment), meta)
      end)
      |> Enum.map(fn
        {:error, msg} -> {:maybe, [msg]}
        any -> any
      end)
    end

  end

  defimpl Inspect do
    import Inspect.Algebra
    import Type, only: :macros

    def inspect(map = %{required: %{__struct__: struct}}, opts) do
      inner = map.required
      |> Map.from_struct
      |> Enum.reject(&(elem(&1, 1) == builtin(:any)))
      |> inner_content(opts)

      concat(["%#{inspect struct}{", inner ,"}"])
    end

    def inspect(%{required: required, optional: optional}, opts) do
      concat(["%{", inner_content(required, optional, opts), "}"])
    end

    def inner_content(required, optional \\ %{}, opts) do
      requireds = Enum.map(required, fn
        {src, dst} when is_atom(src) ->
          concat(["#{src}: ", to_doc(dst, opts)])
        {src, dst} ->
          concat(["required(", to_doc(src, opts), ") => ", to_doc(dst, opts)])
      end)
      optionals = Enum.map(optional, fn {src, dst} ->
        concat(["optional(", to_doc(src, opts), ") => ", to_doc(dst, opts)])
      end)
      concat(Enum.intersperse(requireds ++ optionals, ", "))
    end
  end
end
