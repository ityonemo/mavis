defmodule TypeTest.TestJson do
  @type json :: String.t | number | boolean | nil | [json] | %{optional(String.t) => json}

  def valid_json?(data) do
    json_type = Type.fetch_type!(__MODULE__, :json, [])

    Type.type_match?(json_type, data)
  end
end
