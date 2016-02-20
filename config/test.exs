use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :planning_tool, PlanningTool.Endpoint,
  http: [port: 4001],
  server: false

config :planning_tool,
  :jira_search_issues, PlanningTool.JIRA.SearchIssues.InMemory


# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
# config :planning_tool, PlanningTool.Repo,
#   adapter: Ecto.Adapters.Postgres,
#   username: "postgres",
#   password: "postgres",
#   database: "planning_tool_test",
#   hostname: "localhost",
#   pool: Ecto.Adapters.SQL.Sandbox
