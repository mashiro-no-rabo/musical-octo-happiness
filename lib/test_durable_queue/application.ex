defmodule TestDurableQueue.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      {TestDurableQueue.Tester, [username: "guest", password: "guest"]}
    ]

    opts = [strategy: :one_for_one, name: TestDurableQueue.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
