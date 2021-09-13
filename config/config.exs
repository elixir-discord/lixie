import Config

config :nostrum,
  token: File.read!("token"),
  num_shards: :auto,
  # Added only as needed
  gateway_intents: [
    :guilds
  ]

config :lixie,
  ecto_repos: [Lixie.Repo]

config :lixie, Lixie.Repo,
  database: "data.db"
