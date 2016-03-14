defmodule PlanningTool.JIRA.SearchIssues.InMemory do
  @behaviour PlanningTool.JIRA.SearchIssues

  def execute(:open_sprints) do
    build_issue_keys(:random.uniform(5))
  end
  def execute(_) do
    build_issue_keys(:random.uniform(5))
  end

  defp build_issue_key do
    "PROJ-#{:random.uniform(1000)}"
  end

  defp build_issue_keys(0), do: []
  defp build_issue_keys(count) do
    Enum.map(0..count-1, fn _ -> build_issue_key end)
  end
end
