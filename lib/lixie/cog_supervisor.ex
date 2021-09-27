defmodule Lixie.Cog.Supervisor do
  use Supervisor

  import Logger

  @cog_re ~r{^Lixie\.Cogs\.}

  # TODO: Un/load commands of cogs

  @impl true
  def init(args) do
    children =
      find_cogs()
      |> Enum.map(fn mod ->
        %{id: id} = Lixie.Data.CogState.get_or_insert(inspect(mod))

        args = %{args | cog_id: id}

        {mod, [args]}
      end)

    Supervisor.init(children, strategy: :one_for_one)
  end

  def load_enabled_cogs() do
    for cog <- Lixie.Data.CogState.get_enabled() do
      case Lixie.Cog.load(cog) do
        :ok -> nil
        {:error, reason} -> error("Error encountered starting #{cog}: #{reason}")
      end
    end
  end

  defp find_cogs() do
    :code.all_loaded()
    |> Enum.map(fn {mod, _} -> mod end)
    |> Enum.filter(fn {mod, _} -> inspect(mod) =~ @cog_re end)
  end
end
