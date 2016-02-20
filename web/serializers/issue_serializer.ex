defmodule PlanningToolApi.IssueSerializer do
  use Remodel

  attributes [:key, :summary, :description, :estimate, :developer, :reviewer]

  def key(record) do
    record["key"]
  end

  def summary(record) do
    record["fields"]["summary"]
  end

  def description(record) do
    record["fields"]["description"]
  end

  # Returns remaining estimate in hours
  def estimate(%{"fields" => %{"timetracking" => %{"remainingEstimateSeconds" => value}}}) do
    value / 3600
  end
  def estimate(_) do
    0
  end

  def developer(record) do
    record["fields"]["customfield_10600"]["key"]
  end

  def reviewer(record) do
    record["fields"]["customfield_10601"]["key"]
  end
end
