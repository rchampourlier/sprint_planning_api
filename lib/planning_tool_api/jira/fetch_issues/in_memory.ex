defmodule PlanningToolApi.JIRA.FetchIssues.InMemory do
  @behaviour PlanningToolApi.JIRA.SearchIssues

  def execute(keys) do
    build_issues(keys)
  end

  defp build_issue(key) do
    %{
      "key" => key,
      "fields" => %{
        "summary" => "summary",
        "description" => "description",
        "timeestimate" => :random.uniform(1000000)
      }
    }
  end

  defp build_issues([]), do: []
  defp build_issues([key | other_keys]) do
    [build_issue(key)] ++ build_issues(other_keys)
  end
end
