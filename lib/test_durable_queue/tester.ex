defmodule TestDurableQueue.Tester do
  @moduledoc false
  use GenServer

  # Names
  @queue "test-durable-queue"

  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [x: :y]}
    }
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, [])
  end

  defstruct [:opts, :connection, :channel]

  @impl true
  def init(_) do
    Process.send(self(), :setup, [])

    {:ok, %__MODULE__{opts: nil}}
  end

  @impl true
  def handle_info(:setup, %__MODULE__{opts: opts} = state) do
    new_state = setup(opts, state)
    {:noreply, new_state}
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, _) do
    IO.puts("DOWN...")
    Process.send_after(self(), :setup, 10_000)
    {:noreply, %__MODULE__{opts: nil}}
  end

  def handle_info({:basic_cancel, _}, state) do
    IO.puts("received cancel")
    {:stop, :normal, state}
  end

  def handle_info(info, state) do
    IO.puts("received info: #{Kernel.inspect(info)}")
    {:noreply, state}
  end

  @impl true
  def terminate(_, state) do
    if state.channel && Process.alive?(state.channel.pid), do: AMQP.Channel.close(state.channel)

    if state.connection && Process.alive?(state.connection.pid),
      do: AMQP.Connection.close(state.connection)

    :ok
  end

  defp setup(opts, state) do
    case connect(opts, state) do
      {:ok, conn} ->
        Process.monitor(conn.pid)

        # probably redundant
        if state.channel && Process.alive?(state.channel.pid),
          do: AMQP.Channel.close(state.channel)

        {:ok, chan} = AMQP.Channel.open(conn)

        try do
          IO.puts("trying to declare")
          AMQP.Queue.declare(chan, @queue, durable: true)
          AMQP.Basic.consume(chan, @queue, nil, no_ack: true)
          IO.puts("declare succeed!")
          %__MODULE__{opts: opts, connection: conn}
        catch
          :exit, value ->
            IO.puts("======")
            IO.puts("======")
            IO.puts("======")
            IO.puts("declare failed, retrying...")
            IO.inspect(value)
            IO.puts("======")
            IO.puts("======")
            IO.puts("======")
            Process.send_after(self(), :setup, 10_000)
            %__MODULE__{opts: opts, connection: conn, channel: chan}
        end

      {:error, _} ->
        Process.send_after(self(), :setup, 10_000)

        %__MODULE__{opts: opts}
    end
  end

  defp connect(_, state) do
    if state.connection && Process.alive?(state.connection.pid) do
      {:ok, state.connection}
    else
      AMQP.Connection.open(
        username: "guest",
        password: "guest",
        host: "127.0.0.1",
        port: 5672,
        virtual_host: "xyz",
        timeout: 10_000,
        client_properties: get_client_properties()
      )
    end
  end

  defp get_client_properties do
    {:ok, hostname} = :inet.gethostname()

    project_config = Mix.Project.config()
    app = project_config[:app] |> to_string()
    version = project_config[:version]

    [
      {"hostname", :longstr, to_string(hostname)},
      {"connection_name", :longstr, "#{app}/#{version}"},
      {"pid", :longstr, System.get_pid()},
      {"version", :longstr, version},
      {"actor_id", :longstr, Kernel.inspect(self())}
    ]
  end
end
