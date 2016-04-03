defmodule PlanningTool.JIRA.FetchIssues.InMemory do
  @behaviour PlanningTool.JIRA.FetchIssues

  def execute(keys) do
    build_issues(keys)
  end

  defp build_issue(key) do
    estimate = :random.uniform(100*3600)
    %{
      "key" => key,
      "fields" => %{
        "summary" => "summary",
        "description" => "description",
        "timetracking" => %{
          "remainingEstimateSeconds" => estimate
        },
        "customfield_10600" => %{
          "key" => "author-#{:random.uniform(3)}"
        },
        "customfield_10601" => %{
          "key" => "author-#{:random.uniform(3)}"
        },
        "customfield_10100" => "0|#{key}:"
      }
    }
  end

  defp build_issues([]), do: []
  defp build_issues([key | other_keys]) do
    [build_issue(key)] ++ build_issues(other_keys)
  end
end
