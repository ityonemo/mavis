defmodule Type.Map do
  defstruct [required: [], optional: []]

  @type optional :: {Type.t, Type.t}
  @type requirable :: {integer | atom, Type.t}

  @type t :: %__MODULE__{
    required: [requirable],
    optional: [optional]
  }

  @doc """
  the full union of all possible key values for the passed map.

  ```elixir
  iex> alias Type.Map
  iex> Map.preimage(%Map{optional: [{%Type{name: :integer}, %Type{name: :any}}]})
  %Type{name: :integer}
  iex> Map.preimage(%Map{optional: [{%Type{name: :pos_integer}, %Type{name: :any}}],
  ...>                   required: [{0, %Type{name: :any}}]})
  %Type{name: :non_neg_integer}
  ```
  """

  def preimage(map, filter_type \\ %Type{name: :any})
  def preimage(map, %Type{module: nil, name: :any, params: []}) do
    map
    |> keytypes
    |> Type.union
  end
  def preimage(map, filter_type) do
    (map.required ++ map.optional)
    |> Enum.map(&Type.intersection(elem(&1, 0), filter_type))
    |> Enum.into(%Type.Union{})
  end

  defp keytypes(map) do
    Enum.map(map.required ++ map.optional, &(elem(&1, 0)))
  end

  @doc """
  takes a map, and applies a type to it, returning a list of all
  valid subtypes and what their corresponding results are.

  ```elixir
  iex> alias Type.Map
  iex> Map.segments_of(%Map{optional: [{%Type{name: :neg_integer}, %Type{name: :atom}}]}, -10..10)
  [{-10..-1, %Type{name: :atom}}]
  iex> Map.segments_of(%Map{optional: [{%Type{name: :neg_integer}, %Type{name: :pos_integer}},
  ...>                           {%Type{name: :pos_integer}, %Type{name: :neg_integer}}]}, -10..10)
  [{-10..-1, %Type{name: :pos_integer}},
   {1..10,   %Type{name: :neg_integer}}]
  ```
  """
  def segments_of(map, src_type) do
    import Type, only: [builtin: 1]
    (map.required ++ map.optional)
    |> Enum.flat_map(fn {key_type, val_type} ->
      key_is = Type.intersection(key_type, src_type)
      if key_is == builtin(:none) do
        []
      else
        [{key_is, val_type}]
      end
    end)
  end

  def apply(map, type) do
    map
    |> segments_of(type)
    |> Enum.map(&elem(&1, 1))
    |> Enum.into(%Type.Union{})
  end

  def preimages_of(%{required: required, optional: optional}) do
    Enum.map(optional, fn {k, _} -> k end)
    ++ Enum.map(required, fn {k, _} -> k end)
  end

  # takes a preimage and segments it across all domains, sorting
  # at the end.
  def preimage_segments(map, filter_type) do
    (map.required ++ map.optional)
    |> Enum.map(&Type.intersection(elem(&1, 0), filter_type))
    |> Enum.sort({:asc, Type})
  end

  def required_key?(map, key) do
    key in Enum.map(map.required, &elem(&1, 0))
  end

  defimpl Type.Properties do

    import Type, only: :macros
    alias Type.Map

    use Type

    ##############################################################
    ## comparison

    def group_compare(m1, m2) do
      preimage_cmp = Type.compare(Map.preimage(m1), Map.preimage(m2))
      cond do
        preimage_cmp != :eq -> preimage_cmp
        :eq ->
          m1
          |> Map.preimage_segments(%Type{name: :any})
          |> Enum.flat_map(&Map.preimage_segments(m2, &1))
          |> Enum.each(fn segment ->
            required = check_required(m1, m2, segment)
            required != :eq && throw required

            valtype = Type.compare(Map.apply(m1, segment), Map.apply(m2, segment))
            valtype != :eq && throw valtype
          end)
      end
    catch
      valtype when valtype in [:gt, :lt] -> valtype
    end

    defp check_required(m1, m2, segment) do
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
            optionals = evaluate_optionals(map, tgt, preimage_intersection)
            %Map{optional: optionals -- requireds, required: requireds}
          :empty ->
            builtin(:none)
        end
      end
    end

    defp evaluate_requireds(map, tgt, preimage_intersection) do
      # union the required keys from the map and the target.  This
      # is the full set of required keys from all of the maps.
      all_req_keys = (Enum.map(map.required, &elem(&1, 0)) ++
                      Enum.map(tgt.required, &elem(&1, 0)))
                     |> Enum.uniq

      # check that all required keys exist in the preimage intersection, if
      # it doesn't then we can do a n early eiit.
      if Enum.all?(all_req_keys, &Type.subtype?(&1, preimage_intersection)) do
        req_kv = Enum.map(all_req_keys, fn rq_key ->
          val_type = evaluate_singleton(map, rq_key)
          |> Type.intersection(evaluate_singleton(tgt, rq_key))

          val_type == builtin(:none) && throw :empty

          {rq_key, val_type}
        end)
        {:ok, req_kv}
      else
        :empty
      end
    catch
      :empty -> :empty
    end

    defp evaluate_singleton(map, singleton) do
      optionals = Enum.flat_map(map.optional, fn
        {preimage, image} ->
          if Type.subtype?(singleton, preimage), do: [image], else: []
      end)

      requireds = Enum.flat_map(map.required, fn
        {^singleton, image} -> [image]
        _ -> []
      end)

      Enum.reduce(optionals ++ requireds, &Type.intersection/2)
    end

    defp evaluate_optionals(map, tgt, preimage) do
      # apply the intersected preimages to the first map.
      # this gives us a list of preimage segments, each of
      # which has a consistent image type.
      map
      |> Map.segments_of(preimage)
      |> Enum.flat_map(fn {preimage_segment, image_type} ->
        # resegment each of these preimage segments based on
        # what the target is capable of doing.
        tgt
        |> Map.segments_of(preimage_segment)
        |> Enum.flat_map(fn {preimage_subsegment, new_image_type} ->
          # for each of these smaller segments, find the common
          # type that applies to that segment.
          image_intersect = Type.intersection(image_type, new_image_type)
          if image_intersect == builtin(:none) do
            # if they have nothing in common, drop the segment.
            []
          else
            # otherwise keep this subsegment, attached to the
            # full common ground.
            [{preimage_subsegment, image_intersect}]
          end
        end)
      end)
    end

    def subtype?(_, _), do: raise "unimplemented"

    def usable_as(_, _, _), do: raise "unimplemented"
  end
end
