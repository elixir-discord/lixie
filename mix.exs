defmodule Lixie.MixProject do
  use Mix.Project

  def project do
    [
      app: :lixie,
      version: "0.1.0",
      elixir: "~> 1.12",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Lixie.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:nostrum, git: "https://github.com/Kraigie/nostrum.git"},
      # {:ecto_sql, "~> 3.0"},
      {:ecto_sqlite3, "~> 0.7.1"}
    ]
  end
end
