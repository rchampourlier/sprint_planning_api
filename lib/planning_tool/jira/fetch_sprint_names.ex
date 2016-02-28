# Not used yet.
# Concrete modules (in ./fetch_sprint_names) not implemented.
defmodule PlanningTool.JIRA.FetchSprintNames do

  @doc """
  Fetches sprint names using JIRA JQL Suggestions API (used in their
  JQL field for autocompletion).
  Since it replies a limited number of suggestions, we have to feed
  it with enough characters for the suggestions to match what we're
  searching.
  """
  @callback execute(text :: String.t) :: [String.t]
end
