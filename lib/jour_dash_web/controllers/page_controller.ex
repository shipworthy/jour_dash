defmodule JourDashWeb.PageController do
  use JourDashWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
