defmodule PlanningToolApi.IssuesControllerTest do
  use ExUnit.Case, async: false
  use Plug.Test
  alias PlanningToolApi.Issue
  alias PlanningToolApi.Repo
  alias Ecto.Adapters.SQL
  require IO

  test "GET /issues: returns a list of issues" do
    issue = %Issue{
      identifier: "JT-1234",
      estimate: 6,
      summary: "Some complicated issue, but not so much",
      description: "Bla bla of the product manager that invented this damned issue that will take at least 6 hours of my life!"
    }

    issue_attributes = issue
      |> Map.take([:identifier, :estimate, :summary, :description])
    expected_json = %{issues: [issue_attributes]}
      |> Poison.encode!

    Repo.insert(issue)

    conn = conn(:get, "/api/issues")
    response = PlanningToolApi.Router.call(conn, [])

    assert response.status == 200
    assert response.resp_body == expected_json
  end
end
