defmodule TestDurableQueue.Tester do
  @moduledoc false
  use GenServer

  # Names
  @queue "test-durable-queue"

  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, [])
  end

  defstruct [:opts, :connection, :channel]

  @impl true
  def init(opts) do
    Process.flag(:trap_exit, true)
    Process.send(self(), :setup, [])

    {:ok, %__MODULE__{opts: opts}}
  end

  @impl true
  def handle_info(:setup, state) do
    new_state = setup(state)
    {:noreply, new_state}
  end

  def handle_info({:DOWN, _, :process, _pid, _reason}, state) do
    :lager.log(:warning, self(), "connection is down")
    Process.send_after(self(), :setup, 10_000)
    {:noreply, %__MODULE__{opts: state.opts}}
  end

  def handle_info({:EXIT, _pid, _reason}, state) do
    :lager.log(:warning, self(), "linked exit signal")
    Process.send_after(self(), :setup, 10_000)
    {:noreply, %__MODULE__{opts: state.opts}}
  end

  def handle_info({:basic_cancel, arg}, state) do
    :lager.log(:notice, self(), "received cancel: #{Kernel.inspect(arg)}")
    {:stop, :normal, state}
  end

  def handle_info(info, state) do
    :lager.log(:notice, self(), "handle_info: #{Kernel.inspect(info)}")
    {:noreply, state}
  end

  @impl true
  def terminate(_, state) do
    if state.channel && Process.alive?(state.channel.pid),
      do: AMQP.Channel.close(state.channel)

    if state.connection && Process.alive?(state.connection.pid),
      do: AMQP.Connection.close(state.connection)

    :ok
  end

  defp setup(state) do
    with {:ok, conn} <- open_connection(state),
         {:ok, chan} <- open_channel(conn, state) do
      Process.monitor(conn.pid)

      try do
        :lager.log(:notice, self(), "trying to declare")
        AMQP.Queue.declare(chan, @queue, durable: true)
        :lager.log(:notice, self(), "declare succeed!")

        AMQP.Basic.consume(chan, @queue, nil, no_ack: true)
        :lager.log(:notice, self(), "consume succeed!")

        %__MODULE__{opts: state.opts, connection: conn}
      catch
        :exit, value ->
          :lager.log(:warning, self(), "declare failed: #{Kernel.inspect(value)}")
          Process.send_after(self(), :setup, 10_000)
          %__MODULE__{opts: state.opts, connection: conn, channel: chan}
      end
    else
      {:error, _} ->
        Process.send_after(self(), :setup, 10_000)

        %__MODULE__{opts: state.opts}
    end
  end

  defp open_connection(state) do
    if state.connection && Process.alive?(state.connection.pid) do
      {:ok, state.connection}
    else
      AMQP.Connection.open(
        username: state.opts[:username],
        password: state.opts[:password],
        host: "127.0.0.1",
        port: 5672,
        virtual_host: "xyz",
        timeout: 10_000,
        client_properties: get_client_properties()
      )
    end
  end

  defp open_channel(conn, state) do
    if state.channel && Process.alive?(state.channel.pid) do
      {:ok, state.channel}
    else
      AMQP.Channel.open(conn)
    end
  end

  project_config = Mix.Project.config()
  @app project_config[:app] |> to_string()
  @version project_config[:version]

  defp get_client_properties do
    {:ok, hostname} = :inet.gethostname()

    [
      {"hostname", :longstr, to_string(hostname)},
      {"connection_name", :longstr, "#{@app}/#{@version}"},
      {"pid", :longstr, System.get_pid()},
      {"version", :longstr, @version},
      {"actor_id", :longstr, Kernel.inspect(self())}
    ]
  end
end
