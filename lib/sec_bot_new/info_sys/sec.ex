defmodule SecBotNew.InfoSys.Sec do

  import SweetXml
  use Timex
  alias SecBotNew.InfoSys.Result

  def start_link(query, query_ref, owner, limit) do
    Task.start_link(__MODULE__, :fetch, [query, query_ref, owner, limit])
  end

  def fetch(query_str, query_ref, owner, _limit) do
    query_str
    |> fetch_xml()
    |> xpath(~x"//entry"l, text: ~x"./title/text()", url: ~x"./link/@href", date: ~x"./updated/text()")
    |> reformat_date()
    |> sort_by_date()
    |> clean_text()
    |> send_results(query_ref, owner)
  end

  defp send_results(nil, query_ref, owner) do
    send(owner, {:results, query_ref, []})
  end
  defp send_results(answers, query_ref, owner) do
    results = Enum.map(answers, fn(answer) ->
      %{text: text, url: url, date: date} = answer
      %Result{backend: "Sec", date: date, text: to_string(text), url: ("https://www.sec.gov" <> to_string(url))}
    end)
  send(owner, {:results, query_ref, results})
  end

  defp sort_by_date(list) do
    Enum.sort(list, &(Timex.Date.compare(&1[:date], &2[:date]) == 1))
  end

  defp reformat_date(list) do
    Enum.map(list, fn(item) ->
      %{date: date} = item
      [month, day, year] = String.split(to_string(date), "/")
      |> Enum.map(&(String.to_integer(&1)))
     formatted_date = Timex.to_date({year, month, day})
     Map.merge(item, %{date: formatted_date})
    end)
  end

  defp clean_text(list) do
    Enum.map(list, fn(%{text: text} = item) ->
      new_text = String.replace_prefix(to_string(text), "D - ", "")
      Map.merge(item, %{text: new_text})
    end)
  end

  defp fetch_xml(query_str) do
    {:ok, %HTTPoison.Response{body: body, status_code: 200}} = HTTPoison.get(
     "https://www.sec.gov/cgi-bin/srch-edgar?" <>
     "text=#{URI.encode(query_str)}" <>
     "&start=1&count=80&first=2009&last=2049&output=atom")
    body
  end

end
