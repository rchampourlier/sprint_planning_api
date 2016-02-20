defmodule PlanningTool.JIRA.FetchIssue do

  @doc """
  Fetch a single issue to get all required fields.
  """
  @callback execute(key :: String.t) :: Map.t
end
