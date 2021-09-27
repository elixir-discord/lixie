defmodule Lixie.Data.CogState do
  use Ecto.Schema

  import Ecto.Query

  alias Lixie.Repo

  schema "cog_state" do
    field :cog_module
    field :enabled, :boolean
  end

  @doc """
  Adds the cog to the state-tracking table if it doesn't already exist, and returns the state.

  ### Safety note

  This function is not concurrency-safe. It can fall into a read-then-write race condition.
  It is assumed safe as is because it is to be ran as part of the setup process of the bot.

  PRs to make this safe are welcome.
  """
  def get_or_insert(mod) do
    case Repo.get_by(__MODULE__, cog_module: mod) do
      nil -> Repo.insert!(%__MODULE__{cog_module: mod, enabled: false})
      cog -> cog
    end
  end

  def get_enabled() do
    query = from c in "cog_state",
      where: c.enabled,
      select: c.cog_module

    Repo.all(query)
  end

  def set_state(mod, enabled) do
    Repo.transaction(fn ->
      query = from c in "cog_state",
        where: c.cog_module == ^mod,
        select: c

      case Repo.one(query) do
        {:ok, state} when state.enabled != enabled ->
          Repo.update(state, enabled: enabled)
          :ok
        {:ok, _} -> :already
      end
    end)
  end
end
