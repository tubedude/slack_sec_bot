defmodule SecBotNew.MessageView do
  use SecBotNew.Web, :view

  def render("inquire.json", %{results: results}) do
    text = Enum.map(results, &(format_text(&1)))
    |> Enum.take(3)
    |> Enum.join(" \n")
    %{
      response_type: "in_channel",
      text: "SEC Form-D",
      attachments: [%{text: text}]
    }
  end

  def render("result.json", %{message: result}) do
    {:ok, date} = Timex.format(result.date, "{YYYY}-{M}-{D}")
    %{text: "#{result.url}|#{date}> #{result.text}"}
  end

  defp format_text(result) do
    {:ok, date} = Timex.format(result.date, "{YYYY}-{M}-{D}")
    "<#{result.url}|#{date}> #{result.text}"
  end
end
