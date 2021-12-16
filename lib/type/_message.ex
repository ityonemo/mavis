defmodule Type.Message do

  @moduledoc """
  TBA
  """

  @enforce_keys [:challenge, :target]
  defstruct @enforce_keys ++ [meta: []]

  @type t :: %__MODULE__{
    challenge:   Type.t,
    target: Type.t,
    meta:   [
      file: Path.t,
      line: non_neg_integer,
      warning: atom,
      message: String.t
    ]
  }

  def make(challenge, target, meta) do
    %__MODULE__{challenge: challenge, target: target, meta: meta}
  end

  @doc false
  def _rebrand(:ok, _, _), do: :ok

  def _rebrand({:error, message}, challenge, target) do
    {:error, _rebrand_m(message, challenge, target)}
  end

  def _rebrand({:maybe, messages}, challenge, target) do
    {:maybe, Enum.map(messages, &_rebrand_m(&1, challenge, target))}
  end

  def _rebrand_m(message, challenge, target) do
    %{message | challenge: challenge, target: target}
  end
end
