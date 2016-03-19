-- SprintPlanning is the top-level / application module.
module SprintPlanning where

import Effects exposing (Effects, Never)
import Http
import Html exposing (..)
import Html.Attributes exposing (class, placeholder, style, type')
import Html.Events exposing (on, onClick, targetValue)
import Json.Decode exposing ((:=))
import Json.Decode as Json
import List
import Set
import Task

import Issue
import Issues
import TeamMember
import TeamMemberList


-- MODEL

type Level = WIP | SUCCESS | ERROR
type alias AppStatus =
  { level : Level
  , message : Maybe String
}
type IssueStatus = TODO | DONE
type alias ID = Int
type alias Model =
  { appStatus : AppStatus
  , issues : List Issue.Model
  , sprintName : Maybe String
  , teamMemberList : TeamMemberList.Model
  }

init : (Model, Effects Action)
init =
  ( Model
    { level = WIP, message = Just (buildAppStatusLoadingIssuesMessage WIP Nothing) }
    []
    Nothing
    (TeamMemberList.init [])
  , effectFetchIssues Nothing
  )

getAssignments : List Issue.Model -> List (String, List TeamMember.Assignment)
getAssignments issues =
  let teamMemberNames = Issues.teamMemberNames issues |> Set.toList
  in List.map (\name -> (name, getAssignmentsForName issues name)) teamMemberNames

getAssignmentsForName : List Issue.Model -> String -> List (TeamMember.Role, Int)
getAssignmentsForName issues name =
  List.map (\role -> (role, calculateAssignmentForNameAndRole issues name role)) [TeamMember.Developer, TeamMember.Reviewer]

calculateAssignmentForNameAndRole : List Issue.Model -> String -> TeamMember.Role -> Int
calculateAssignmentForNameAndRole issues teamMemberName role =
  let
    is : TeamMember.Role -> Issue.Model -> Bool
    is role issue =
      let maybeName =
        case role of
          TeamMember.Developer -> issue.developerName
          TeamMember.Reviewer -> issue.reviewerName
      in
        case maybeName of
          Nothing -> False
          Just name -> name == teamMemberName
  in
    List.filter (is role) issues
      |> sumEstimates

sumEstimates : List Issue.Model -> Int
sumEstimates issues =
  List.map (\i -> i.estimate) issues
    |> List.foldl (+) 0

getIssuesForStatus : IssueStatus -> Model -> List Issue.Model
getIssuesForStatus status model =
  case status of
    TODO -> List.filter (\i -> i.developerName == Nothing || i.reviewerName == Nothing) model.issues
    DONE -> List.filter (\i -> i.developerName /= Nothing && i.reviewerName /= Nothing) model.issues

buildAppStatusLoadingIssuesMessage : Level -> Maybe String -> String
buildAppStatusLoadingIssuesMessage level maybeSprintName =
  let
    issuesLabel = case maybeSprintName of
      Nothing -> "issues for open sprints"
      Just sprintName -> "issues for " ++ sprintName
  in
    case level of
      WIP -> "loading " ++ issuesLabel
      SUCCESS -> "loaded " ++ issuesLabel
      ERROR -> "failed to load " ++ issuesLabel


-- UPDATE

type Action
  = FetchIssues
  | HideAppStatusLine
  | ModifyIssue Issue.Model Issue.Action
  | ModifyTeamMemberList TeamMemberList.Action
  | ReceivedIssues (Maybe (List Issue.Model))
  | UpdateSprintName String

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of

    FetchIssues ->
      let appStatus =
        { level = WIP
        , message = Just (buildAppStatusLoadingIssuesMessage WIP model.sprintName)
        }
      in
        ( { model | appStatus = appStatus }
        , effectFetchIssues model.sprintName
        )

    HideAppStatusLine ->
      let appStatus =
        { level = WIP
        , message = Nothing
        }
      in
        ( { model | appStatus = appStatus } , Effects.none )

    ModifyIssue issue issueAction ->
      let
        -- Beware of comparing on the key, otherwise the issue
        -- would not be recognized if it's run in a callback
        -- (Effects result). Also beware of applying the update
        -- on the correct issue (i, not issue)!
        updateIssue i = if i.key == issue.key
          then Issue.update issueAction i
          else (i, Effects.none)
        issuesAndEffects = List.map updateIssue model.issues
        updatedIssues = List.map fst issuesAndEffects
        effect = List.map snd issuesAndEffects
          |> List.filter (\e -> e /= Effects.none)
          |> List.head
          |> Maybe.withDefault Effects.none
          |> Effects.map (ModifyIssue issue)
      in
        ({ model
            | issues = updatedIssues
            , teamMemberList =
              TeamMemberList.updateAssignments (getAssignments updatedIssues) model.teamMemberList
          }, effect)

    ModifyTeamMemberList teamMemberListAction ->
      ({ model
          | teamMemberList = TeamMemberList.update teamMemberListAction model.teamMemberList
        }
      , Effects.none )

    -- When we receive issues (on app initialization or when fetching issues
    -- from a specified sprint), we want to add team members from values
    -- present in the issues.
    ReceivedIssues maybeIssues ->
      let appStatus =
        { level = SUCCESS
        , message = Just (buildAppStatusLoadingIssuesMessage SUCCESS model.sprintName)
        }
      in
        case maybeIssues of
          Nothing ->
            ( { model | appStatus = appStatus } , Effects.none )
          Just issues ->
            let
              namesFromIssues = Issues.teamMemberNames issues |> Set.toList
            in
              ({ model
                  | appStatus = appStatus
                  , issues = issues
                  , teamMemberList = model.teamMemberList
                    |> TeamMemberList.updateAddTeamMemberWithNames namesFromIssues
                    |> TeamMemberList.updateAssignments (getAssignments issues)
                }, Effects.none )

    UpdateSprintName name ->
      ({ model | sprintName = Just name }, Effects.none )


-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  let
    issuesTodo = getIssuesForStatus TODO model
    issuesDone = getIssuesForStatus DONE model
    teamMemberNames = TeamMemberList.getTeamMemberNames model.teamMemberList
    statusLineClassSuffix = case model.appStatus.level of
      WIP -> "wip"
      SUCCESS -> "success"
      ERROR -> "error"

    statusLine : List Html
    statusLine = case model.appStatus.message of
      Nothing -> []
      Just message -> [
        div
          [ class ("mui-row status-line status-line--" ++ statusLineClassSuffix) ]
          [ div [ class "mui-col-md-11" ] [ text message ]
          , span
            [ class "mui-col-md-1 mui-btn mui-btn--small mui-btn--flat status-line__btn"
            , onClick address HideAppStatusLine
            ]
            [ text "Hide" ]
          ]
        ]

  in
    div [ class "sprint-planning" ]
      [ div [ class "mui-col-md-8" ]
        [ div [ class "mui-panel configuration" ]
          [ div [ class "configuration" ]
            ([ legend [] [ text "Configuration" ]
            , div [ class "mui-row" ]
              [ div [ class "mui-col-md-6" ]
                [ div [ class "mui-textfield" ]
                  [ input
                    [ type' "text"
                    , placeholder "Enter a sprint name"
                    , on "input" targetValue (\str -> Signal.message address (UpdateSprintName str))
                    ]
                    []
                  ]
                ]
              , div [ class "mui-col-md-6" ]
                [ button
                  [ class "mui-btn mui-btn--primary", onClick address FetchIssues ]
                  [ text "Fetch sprint's issues" ]
                ]
              ]
            ] ++ statusLine )
          ]
        , h2 [] [ text "Issues - TODO" ]
        , div
          [ class "mui-panel" ]
          [ div [] [ viewIssues address issuesTodo teamMemberNames ] ]
        , h2 [] [ text "Issues - DONE" ]
        , div
          [ class "mui-panel" ]
          [ div [] [ viewIssues address issuesDone teamMemberNames ] ]
        ]
      , div [ class "team-members-box mui-col-md-4" ]
        [ h2 [] [ text "Team Members" ]
        , div [ class "mui-panel" ] [ viewTeamMembers address model ]
        ]
      ]

viewIssues : Signal.Address Action -> List Issue.Model -> List String -> Html
viewIssues address issues teamMemberNames =
  let
    viewIssue : Issue.Model -> Html
    viewIssue issue = Issue.view (Signal.forwardTo address (ModifyIssue issue)) issue teamMemberNames
  in
    div []
      [ table [ class "mui-table issues-list" ]
        [ thead []
          [ tr []
            [ th [] [ text "Issue" ]
            , th [] [ text "Estimate" ]
            , th [] [ text "Developer" ]
            , th [] [ text "Reviewer" ]
            ]
          ]
        , tbody [] (List.map viewIssue issues)
        ]
      ]

viewTeamMembers : Signal.Address Action -> Model -> Html
viewTeamMembers address model =
  TeamMemberList.view (Signal.forwardTo address ModifyTeamMemberList) model.teamMemberList


-- EFFECTS

effectFetchIssues : Maybe String -> Effects Action
effectFetchIssues maybeSprintName =
  let
    url_base = "/api/issues"
    url = case maybeSprintName of
      Nothing -> Http.url url_base [ ]
      Just name -> Http.url url_base [ ("sprintName", name) ]
  in
    Http.get (Json.list decodeIssue) url
      |> Task.toMaybe
      |> Task.map ReceivedIssues
      |> Effects.task

-- We must beware that if the decoder fails to decode
-- a value (for example an estimate is null, and not
-- an int), the whole decoder will return Nothing
-- without more warning.
decodeIssue : Json.Decoder Issue.Model
decodeIssue =
  Json.object5 Issue.init
    ("key" := Json.string)
    ("summary" := Json.string)
    (Json.oneOf [ "estimate" := Json.int, Json.succeed 0 ])
    (Json.maybe ( "developer" := Json.string ))
    (Json.maybe ( "reviewer" := Json.string ))
