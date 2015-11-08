# See [Ecto.Migration](http://hexdocs.pm/ecto/Ecto.Migration.html)
# for details.
defmodule PlanningToolApi.Repo.Migrations.CreateIssues do
  use Ecto.Migration

  def change do
    create table(:issues) do
      add :identifier, :string
      add :estimate, :integer
      add :summary, :string
      add :description, :string

      timestamps
    end
  end
end
