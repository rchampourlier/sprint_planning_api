defmodule PlanningTool.PageController do
  use PlanningTool.Web, :controller

  def index(conn, _params) do
    render conn, "index.html" 
  end
end
