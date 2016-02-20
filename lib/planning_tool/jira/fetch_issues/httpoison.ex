# Module to get a single issue from JIRA.
defmodule PlanningTool.JIRA.FetchIssues.HTTPoison do
  @behaviour PlanningTool.JIRA.FetchIssues

  def execute(keys) do
    {:ok, _pid} = pool_for_get_issue()
    start_get_issue_jobs(keys)
    collect_job_responses(keys)
  end

  defp start_get_issue_jobs(keys) do
    caller = self
    Enum.each(keys, fn(key) ->
      spawn(fn() -> execute_get_issue_job(caller, key) end)
    end)
  end

  defp execute_get_issue_job(caller, key) do
    response = pooled_get_issue(key)
    send caller, {:ok, response}
  end

  defp collect_job_responses(keys) do
    Enum.map(1..length(keys), fn(_) ->
      get_job_response()
    end)
  end

  defp get_job_response do
    receive do
      {:ok, response} -> response
    end
  end

  defp pool_for_get_issue() do
    poolboy_config = [
      {:name, {:local, :get_issue_workers_pool}},
      {:worker_module, PlanningTool.JIRA.FetchIssues.HTTPoison.FetchIssueWorker},
      {:size, 0},
      {:max_overflow, 10}
    ]

    children = [
      :poolboy.child_spec(:get_issue_workers_pool, poolboy_config, [])
    ]

    options = [
      strategy: :one_for_one,
      name: FetchIssueWorker
    ]

    case Supervisor.start_link(children, options) do
      {:ok, pid} -> {:ok, pid}
      {:error, {:already_started, pid}} -> {:ok, pid}
    end
  end

  defp pooled_get_issue(key) do
    :poolboy.transaction(:get_issue_workers_pool, fn(pid) ->
      PlanningTool.JIRA.FetchIssues.HTTPoison.FetchIssueWorker.execute(pid, key)
    end)
  end

  defmodule FetchIssueWorker do
    use GenServer

    def start_link([]) do
      GenServer.start_link(__MODULE__, :worker)
    end

    def init(state) do
      {:ok, state}
    end

    def handle_call(key, from, state) do
      result = get_issue_module().execute(key)
      {:reply, result, state}
    end

    def execute(pid, key) do
      GenServer.call(pid, key)
    end

    def get_issue_module() do
      Application.get_env(:planning_tool, :jira_get_issue)
    end
  end
end
