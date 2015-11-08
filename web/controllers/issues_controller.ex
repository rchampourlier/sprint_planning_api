defmodule PlanningToolApi.IssuesController do
  use PlanningToolApi.Web, :controller
  alias PlanningToolApi.Issue

  def index(conn, _params) do
    present_issue = fn i -> Map.take(i, [:identifier, :estimate, :summary, :description]) end
    issues = Repo.all(Issue)
      |> Enum.map present_issue

    json conn, %{issues: issues}
  end
end
