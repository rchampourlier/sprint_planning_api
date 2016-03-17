# Module to get a list of issues from JIRA.
#
# One process per JIRA is spawned to perform
# FetchIssue.execute.
#
defmodule PlanningTool.JIRA.FetchIssues.HTTPoison do
  @behaviour PlanningTool.JIRA.FetchIssues

  def execute(keys) do
    parent_pid  = self()
    Enum.map keys, fn key ->
      spawn_fetch_process key, parent_pid
    end
    Enum.map keys, fn _ ->
      receive do
        response -> response
      end
    end
  end

  defp fetch_issue_module() do
    Application.get_env(:planning_tool, :jira_fetch_issue)
  end

  defp spawn_fetch_process(key, parent_pid) do
    spawn fn ->
      case fetch_issue_module.execute(key) do
        { :fetch_ok, response } -> send parent_pid, response
        { :fetch_error, _ } ->
          IO.puts "Fetch error with issue #{key}. Retrying."
          spawn_fetch_process(key, parent_pid)
      end
    end
  end
end
