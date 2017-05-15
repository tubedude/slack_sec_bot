defmodule SecBotNew.Web.PageController do
  use SecBotNew.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
