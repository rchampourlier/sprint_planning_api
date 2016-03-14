# Search JIRA issues according to some pre-defined queries.
# Returns a list of strings of the JIRA issue keys.
#
# TECHNICAL-DEBT: forcing maxResults to 200, not handling paginated
#   responses.
defmodule PlanningTool.JIRA.SearchIssues.HTTPoison do
  @behaviour PlanningTool.JIRA.SearchIssues

  def execute(:open_sprints) do
    jql = "SPRINT in openSprints()"
    params = [ {:jql, jql}, {:fields, "id"}, {:startAt, 0}, {:maxResults, 200} ]
    get!("/search", [], [params: params])
      |> Map.get(:body)
  end
  def execute(%{sprint: sprintName}) do
    jql = "SPRINT = \"" <> sprintName <> "\""
    params = [ {:jql, jql}, {:fields, "id"}, {:startAt, 0}, {:maxResults, 200} ]
    get!("/search", [], [params: params])
      |> Map.get(:body)
  end
  def execute(%{jql: jql}) do
    params = [ {:jql, jql}, {:fields, "id"}, {:startAt, 0}, {:maxResults, 200} ]
    results = get!("/search", [], [params: params])
      |> Map.get(:body)
    results
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
