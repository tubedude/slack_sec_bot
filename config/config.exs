# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :sec_bot_new, SecBotNew.Web.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "S2YIG+mlPrBYd2OjGFZClHk7+mzL8PMQE3srvAMbBqxwKTX6gobI/6fjbr13zKzv",
  render_errors: [view: SecBotNew.Web.ErrorView, accepts: ~w(html json)],
  pubsub: [name: SecBotNew.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"
