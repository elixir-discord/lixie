defmodule Lixie.Cog do
  @moduledoc """
  A behaviour module for defining a set of functionality that can be loaded and unloaded.

  ## Important notes

  This behaviour assumes the module is a GenServer, and the use macro will call
  `GenServer.__using__`.

  Do not manually un/register commands. Return the command registration maps using `commands/1`
   instead.

  ## Lifecycle

  Cogs follow a specific flow:
  1. Process spawned - This happens regardless of whether the cog is loaded or not. There
  should be minimal prep work done in `GenServer.init/1`,
  2. Commands registered - If an empty list is returned, no commands registered. This is the
  default for `commands/1`.
  3. Cog loaded - After `load/1` returns, the cog will start receiving events, and commands if any
  were registered.
  4. Commands unregistered - This happens immediately before unloading to ensure commands aren't
  missed.
  5. Cog unloaded - On user command or the bot is stopped, the cog will be unloaded.
  6, Process stopped - This will happen only on crash or bot stop. The cog may be loaded again
  before this stage.

  ## Usage

  All events, save interactions, from the Discord gateway will be forwarded to the cog via
  `handle_discord/2`. In the future, this may change to an opt-in system. Interactions will come
  through `handle_interaction/3`, See functions for details.

  The cog can stop itself, which will trigger deregistration of interactions and commands before
  calling `unload/1`.

  Unless stated otherwise, error returns are supported for convenience of logging only, and don't
  change the flow of execution. Errors will be cast to the cog to enable asynchronous recovery.
  """

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      @behaviour Lixie.Cog

      use GenServer, opts

      def start_link(args) do
        GenServer.start_link(__MODULE__, args, name: {:global, inspect(__MODULE__)})
      end

      @impl true
      def handle_call(:load, state) do
        case __MODULE__.load(state) do
          {:ok, state} -> {:reply, :ok, state}
          {:error, reason, state} -> {:reply, {:error, reason}, state}
        end
      end

      @impl true
      def handle_call(:commands, state), do: {:reply, __MODULE__.commands(state), state}
    end
  end

  @spec load(cog) :: :ok | {:error, reason} when cog: atom(), reason: term()
  def load(cog), do: GenServer.call(cog, :load)

  @doc """
  Invoked before events are sent to the cog so it can do any setup work it needs to do, ie load
  configurations, check a database, etc.

  Returning an error will stop the loading of the cog, but not stop the process.
  """
  @callback load(state) :: {:ok, state} | {:error, reason, state}
    when state: term(), reason: term()

  @doc """
  Invoked before the cog is stopped so it can do any cleanup work it needs to do, ie save
  configurations, close connections, etc.
  """
  @callback unload(state) :: {:ok, state} | {:error, reason, state}
    when state: term(), reason: term()

  @doc """
  Invoked on all Discord events, save interactions.
  """
  @callback handle_discord(payload, state) :: {:ok, state} | {:stop | :error, reason, state}
    when payload: term(), state: term(), reason: term()

  @doc """
  Invoked on commands registered by this cog, and all interactions. In the future, this will
  only invoke on interactions created by this cog.
  """
  @callback handle_interaction(type, payload, state)
    :: {:ok, state} | {:stop | :error, reason, state}
    when type: :command | :component, payload: term(), state: term(), reason: term()

  @doc """
  Invoked to get the commands that the cog listens for. Command interactions received by the cog
  will be limited to the commands returned by this method.
  """
  @spec commands(state) :: [command] when state: term(), command: map()
  def commands(_), do: []

  # These functions will be used later when component filtering is implemented

  def get_nonce(%{interaction_nonce: nonce} = state) do
    <<cog::3, date::24, _::5>> = nonce

    <<_::3, date::24, inc::5>> = if date != (new_date = hours_from_dt(DateTime.utc_now)) do
      <<cog, new_date, 0>>
    else nonce end

    {<<cog, date, inc>>, %{state | interaction_nonce: <<cog, date, inc + 1>>}}
  end

  def dt_from_nonce(<<_::3, dt::24, _::5>>) do
    DateTime.add(Lixie.Utils.epoch, dt * 3600)
  end

  defp hours_from_dt(dt) do
    DateTime.diff(dt, Lixie.Utils.epoch) |> Integer.floor_div(3600)
  end

  defoverridable commands: 1
end
