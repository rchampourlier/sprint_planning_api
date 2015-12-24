defmodule PlanningToolApi.JIRA.SearchIssues do

  @doc """
  Perform a search for issues matching the specified criteria.
  Available criteria: [:open_sprints].
  Returns an array of strings representing the issue keys.
  """
  @callback execute(criteria :: Atom.t) :: [String.t]
end
