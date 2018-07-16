defmodule TestDurableQueue.MixProject do
  use Mix.Project

  def project do
    [
      app: :test_durable_queue,
      version: "0.1.0",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [mod: {TestDurableQueue.Application, []}, extra_applications: [:logger]]
  end

  defp deps do
    [
      {:amqp, "~> 1.0"},
      {:ranch_proxy_protocol, "~> 2.0", override: true}
    ]
  end
end
