defmodule PlanningTool.IssuesController do
  use PlanningTool.Web, :controller

  # GET index
  def index(conn, _params) do
    response = jira_fetch_issues()
      |> PlanningTool.IssueSerializer.to_map
    json conn, response
  end

  # POST update
  def update(conn, %{"id" => id, "developer" => name}) do
    result = jira_update_issue_module.execute(id, %{"fields" => %{"customfield_10600" => %{"name" => name}}})
    json conn, result |> Atom.to_string
  end
  def update(conn, %{"id" => id, "reviewer" => name}) do
    result = jira_update_issue_module.execute(id, %{"fields" => %{"customfield_10601" => %{"name" => name}}})
    json conn, result |> Atom.to_string
  end

  defp jira_fetch_issues do
    jira_search_issues_module.execute(:open_sprints)
      |> jira_fetch_issues_module.execute
  end

  defp jira_search_issues_module do
    Application.get_env(:planning_tool, :jira_search_issues)
  end

  defp jira_fetch_issues_module do
    Application.get_env(:planning_tool, :jira_fetch_issues)
  end

  defp jira_update_issue_module do
    Application.get_env(:planning_tool, :jira_update_issue)
  end
end
