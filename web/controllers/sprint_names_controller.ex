# Not used yet.
defmodule PlanningTool.SprintNamesController do
  use PlanningTool.Web, :controller

  # GET index
  def index(conn, _params) do
    response = jira_fetch_sprint_names()
    json conn, response
  end

  defp jira_fetch_sprint_names do
    jira_fetch_sprint_names_module.execute()
  end

  defp jira_fetch_sprint_names_module do
    Application.get_env(:planning_tool, :jira_fetch_sprint_names)
  end
end
