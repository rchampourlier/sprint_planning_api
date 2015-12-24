# Search JIRA issues according to some pre-defined queries.
# Returns a list of strings of the JIRA issue keys.
defmodule PlanningToolApi.JIRA.SearchIssues.HTTPoison do
  @behaviour PlanningToolApi.JIRA.SearchIssues

  def execute(:open_sprints) do
    get!("/search?jql=Sprint+in+openSprints()&fields=id")
      |> Map.get :body
  end

  # HTTPoison API-wrapping
  use HTTPoison.Base

  def process_url(path) do
    username = System.get_env("JIRA_USERNAME")
    password = System.get_env("JIRA_PASSWORD")
    domain = System.get_env("JIRA_DOMAIN")

    "https://" <> username <> ":" <> password <> "@" <> domain <> "/rest/api/2" <> path
  end

  def process_response_body(body) do
    body
      |> Poison.decode!
      |> Map.get("issues")
      |> Enum.map(fn(issue) -> Map.get(issue, "key") end)
  end
end
