defmodule Lixie.Data.CogState do
  use Ecto.Schema

  import Ecto.Query

  alias Lixie.Repo

  schema "cog_state" do
    field :cog_module
    field :enabled, :boolean
  end

end
