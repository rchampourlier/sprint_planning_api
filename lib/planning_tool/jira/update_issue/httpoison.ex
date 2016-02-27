defmodule PlanningTool.JIRA.UpdateIssue.HTTPoison do
  @behaviour PlanningTool.JIRA.UpdateIssue

  def execute(issue_key, body) do
    body_json = Poison.encode!(body)
    put!(
      "/issue/#{issue_key}",
      body_json,
      [{"Content-Type", "application/json"}]
    )

    IO.puts "UPDATE issue #{issue_key} with #{body_json}"
    :ok
  end

  # HTTPoison API-wrapping
  use HTTPoison.Base

  defp process_url(path) do
    username = System.get_env("JIRA_USERNAME")
    password = System.get_env("JIRA_PASSWORD")
    domain = System.get_env("JIRA_DOMAIN")

    "https://" <> username <> ":" <> password <> "@" <> domain <> "/rest/api/2" <> path
  end
end
