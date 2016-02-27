defmodule PlanningTool.JIRA.UpdateIssue.InMemory do
  @behaviour PlanningTool.JIRA.UpdateIssue

  def execute(issue_key, body) do
    developer = body["fields"]["customfield_10600"]["name"]
    reviewer = body["fields"]["customfield_10601"]["name"]

    result = :ok
    IO.puts "UPDATE issue #{issue_key} with developer #{developer}, reviewer #{reviewer} => #{result |> Atom.to_string}"

    result
  end
end
