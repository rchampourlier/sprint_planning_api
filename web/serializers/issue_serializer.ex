defmodule PlanningToolApi.IssueSerializer do
  use Remodel

  attributes [:key, :summary, :description, :estimate]

  def key(record) do
    record["key"]
  end

  def summary(record) do
    record["fields"]["summary"]
  end

  def description(record) do
    record["fields"]["description"]
  end

  def estimate(record) do
    record["fields"]["timetracking"]["remainingEstimateSeconds"]
  end
end
