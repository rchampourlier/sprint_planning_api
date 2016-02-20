defmodule PlanningTool.JIRA.FetchIssues do

  @doc """
  Fetch complete issue data for issues specified by key.
  """
  @callback execute(keys :: [String.t]) :: [Map.t]
end
