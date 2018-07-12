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
    [
      mod: {TestDurableQueue.Application, []}
    ]
  end

  defp deps do
    [
      {:amqp, "~> 1.0"},
      {:ranch_proxy_protocol, github: "heroku/ranch_proxy_protocol", override: true}
    ]
  end
end
