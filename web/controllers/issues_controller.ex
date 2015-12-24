defmodule PlanningToolApi.IssuesController do
  use PlanningToolApi.Web, :controller

  def index(conn, _params) do
    response = jira_fetch_issues()
      |> PlanningToolApi.IssueSerializer.to_map
    json conn, response
  end

  def jira_fetch_issues do
    jira_search_issues_module.execute(:open_sprints)
      |> jira_fetch_issues_module.execute
  end

  defp jira_search_issues_module do
    Application.get_env(:planning_tool_api, :jira_search_issues)
  end

  defp jira_fetch_issues_module do
    Application.get_env(:planning_tool_api, :jira_fetch_issues)
  end
end
