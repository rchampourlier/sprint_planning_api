defmodule PlanningToolApi.Router do
  use PlanningToolApi.Web, :router

  # pipeline :browser do
  #   plug :accepts, ["html"]
  #   plug :fetch_session
  #   plug :fetch_flash
  #   plug :protect_from_forgery
  #   plug :put_secure_browser_headers
  # end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # scope "/", PlanningToolApi do
  #   pipe_through :browser # Use the default browser stack
  #
  #   get "/", PageController, :index
  # end

  scope "/", PlanningToolApi do
    pipe_through :api

    resources "/issues", IssuesController
  end
end
