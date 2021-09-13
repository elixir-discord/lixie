defmodule Lixie.Repo do
  use Ecto.Repo,
    otp_app: :lixie,
    adapter: Ecto.Adapters.SQLite3
end
