defmodule PlanningTool.JIRA.UpdateIssue do

  @doc """
  Updates a JIRA issue according to the specified attributes.
  """
  @callback execute(issue_key :: String.t, body :: Map.t) :: Atom.t
end
