defmodule PlanningToolApi.Issue do
  use Ecto.Model

  schema "issues" do
    field :identifier
    field :estimate, :integer
    field :summary
    field :description

    timestamps
  end
end
