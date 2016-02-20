defmodule PlanningTool.JIRA.FetchIssues.InMemory do
  @behaviour PlanningTool.JIRA.SearchIssues

  def execute(keys) do
    build_issues(keys)
  end

  defp build_issue(key) do
    %{
      "key" => key,
      "fields" => %{
        "summary" => "summary",
        "description" => "description",
        "timetracking" => %{
          "remainingEstimateSeconds" => :random.uniform(100)
        },
        "customfield_10600" => %{
          "key" => "author-#{:random.uniform(3)}"
        },
        "customfield_10601" => %{
          "key" => "author-#{:random.uniform(3)}"
        }
      }
    }
  end

  defp build_issues([]), do: []
  defp build_issues([key | other_keys]) do
    [build_issue(key)] ++ build_issues(other_keys)
  end
end
