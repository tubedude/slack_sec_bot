defmodule SecBotNew.InfoSys do

  @backends [SecBotNew.InfoSys.Sec]

  defmodule Result do
    defstruct date: nil, text: nil, url: nil, backend: nil
  end
  def start_link(backend, query, query_ref, owner, limit) do
    backend.start_link(query, query_ref, owner, limit)
  end

  defp compute(query, opts \\ []) do
    limit = opts[:limit] || 10
    backends = opts[:backends] || @backends

    backends
    |> Enum.map(&spawn_query(&1, query, limit))
    |> await_results(opts)
    |> Enum.take(limit)
  end

  def fetch_result(%{"text" => text, "response_url" => response_url}) do
    results = compute(text)
    results_count = Enum.count(results)
    {:ok, json_body} = case results_count do
      0 ->
        %{"response_type"=> "ephemeral", "text"=> "No answer found for: #{text}"}
        |> Poison.encode
      _ ->
        Phoenix.View.render(SecBotNew.MessageView, "inquire.json", results: results)
        |> Poison.encode
    end
    HTTPoison.post(response_url, json_body)
  end

  defp spawn_query(backend, query, limit) do
    query_ref = make_ref()
    opts = [backend, query, query_ref, self(), limit]
    {:ok, pid} = Supervisor.start_child(SecBotNew.InfoSys.Supervisor, opts)
    monitor_ref = Process.monitor(pid)
    {pid, monitor_ref, query_ref}
  end

  defp await_results(children, opts) do
    timeout = opts[:timeout] || 5000
    timer = Process.send_after(self(), :timedout, timeout)
    results = await_result(children, [], :infinity)
    cleanup(timer)
    results
  end

  defp await_result([head|tail], acc, timeout) do
    {pid, monitor_ref, query_ref} = head

    receive do
      {:results, ^query_ref, results} ->
        Process.demonitor(monitor_ref, [:flush])
        await_result(tail, results ++ acc, timeout)
      {:DOWN, ^monitor_ref, :process, ^pid, _reason} ->
        await_result(tail, acc, timeout)
      :timedout ->
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)
    after
      timeout ->
        kill(pid, monitor_ref)
        await_result(tail, acc, 0)
    end
  end

  defp await_result([], acc, _) do
    acc
  end

  defp kill(pid, ref) do
    Process.demonitor(ref, [:flush])
    Process.exit(pid, :kill)
  end

  defp cleanup(timer) do
    :erlang.cancel_timer(timer)
    receive do
      :timedout -> :ok
    after
      0 -> :ok
    end
  end
end
