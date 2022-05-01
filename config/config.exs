import Config

# whether or not mavis will validate certain things when called
# by the `Type.type/1` macro
config :mavis, :validation, Mix.env() in [:test, :dev]
