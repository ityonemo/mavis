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
  def preimage(map) do
    map
    |> keytypes
    |> Type.union
  end

  defp keytypes(map) do
    Enum.map(map.required ++ map.optional, &(elem(&1, 0)))
  end

  @doc """
  takes a map, and applies a type to it, returning a list of all
  valid subtypes and what their corresponding results are.

  ```elixir
  iex> alias Type.Map
  iex> Map.image_of(%Map{optional: [{%Type{name: :neg_integer}, %Type{name: :atom}}]}, -10..10)
  [{-10..-1, %Type{name: :atom}}]
  iex> Map.image_of(%Map{optional: [{%Type{name: :neg_integer}, %Type{name: :pos_integer}},
  ...>                           {%Type{name: :pos_integer}, %Type{name: :neg_integer}}]}, -10..10)
  [{-10..-1, %Type{name: :pos_integer}},
   {1..10,   %Type{name: :neg_integer}}]
  ```
  """
  def image_of(map, src_type) do
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

  defimpl Type.Properties do

    import Type, only: :macros
    use Type
    alias Type.Map

    intersection do
      def intersection(map, tgt = %Map{}) do
        # find the intersection of the preimages
        preimage_intersection = map
        |> Map.preimage
        |> Type.intersection(Map.preimage(tgt))

        # apply the intersected preimages to the first map.
        # this gives us a list of preimage segments, each of
        # which has a consistent image type.
        optionals = map
        |> Map.image_of(preimage_intersection)
        |> Enum.flat_map(fn {preimage_segment, image_type} ->

          # resegment each of these preimage segments based on
          # what the target is capable of doing.
          tgt
          |> Map.image_of(preimage_segment)
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

        %Map{optional: optionals}
      end
    end

    def subtype?(_, _), do: raise "unimplemented"

    def usable_as(_, _, _), do: raise "unimplemented"
  end
end
