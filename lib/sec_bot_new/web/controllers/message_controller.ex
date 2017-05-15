defmodule SecBotNew.Web.MessageController do
  use SecBotNew.Web, :controller
  require Logger

  @action_regex ~r/(?<command>help|list|add)\s?(?<args>.*)/

  plug :get_action

  def inquire(conn, %{"command" => "/sec"}, %{"command" => "help"}) do
    conn
    |> put_status(:ok)
    |> json(%{response_type: "ephemeral", text: "/sec [term to be searched]\n/sec company-name=[name]\n/sec also takes boolean operators (AND, OR)"})
  end
  def inquire(conn, %{"command" => "/sec"} = params, nil) do
    {:ok, _pid} = Task.start_link(SecBotNew.InfoSys, :fetch_result, [params])
    conn
    |> put_status(:ok)
    |> json(%{"response_type": "in_channel"})

  end
  def inquire(conn, %{"command" => command}, _) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{text: "[Error] Did not pattern match: #{command} #{conn.assigns.action["command"]}"})
  end

  def action(conn, _) do apply(__MODULE__, action_name(conn),
           [conn, conn.params, conn.assigns.action])
  end

  defp get_action(conn, _) do
    text = conn.params["text"]
    Logger.debug inspect(text)
    Logger.debug "Regex result: -->#{Regex.named_captures(@action_regex, text)["args"]}<--"
    conn
    |> assign(:action, Regex.named_captures(@action_regex, text))
  end

end
