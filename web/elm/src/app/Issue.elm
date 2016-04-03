module Issue (Action, Model, init, update, view) where

import Effects exposing (Effects, Never)
import Http
import Html exposing (..)
import Html.Attributes exposing (class, key)
import Json.Decode exposing ((:=))
import Json.Decode
import Task

import Mui


-- MODEL

type Role = Developer | Reviewer

type alias Model =
  { key : String
  , summary : String
  , rank : String
  , estimate : Int
  , developerName : Maybe String
  , reviewerName : Maybe String
  , isBeingUpdated : Bool
  }

init : String -> String -> String -> Int -> Maybe String -> Maybe String -> Model
init key summary rank estimate maybeDeveloperName maybeReviewerName =
  { key = key
  , summary = summary
  , rank = rank
  , estimate = estimate
  , developerName = maybeDeveloperName
  , reviewerName = maybeReviewerName
  , isBeingUpdated = False
  }


-- UPDATE

type Action
  = Assign Role Mui.Action
  | Unassign Role
  | UpdateProcessed Role (Maybe String) (Maybe String) (Maybe String)

update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of

    Assign role muiAction ->
      let
        selectedTeamMemberName = Mui.selectedID muiAction
      in
        case role of
          Developer ->
            ({ model
              | isBeingUpdated = True
              , developerName = selectedTeamMemberName
            }, effectUpdateIssue model.key role selectedTeamMemberName model.developerName)
          Reviewer ->
            ({ model
              | isBeingUpdated = True
              , reviewerName = selectedTeamMemberName
            }, effectUpdateIssue model.key role selectedTeamMemberName model.reviewerName)

    Unassign role ->
      case role of
        Developer ->
          ({ model
            | isBeingUpdated = True
            , developerName = Nothing
          }, effectUpdateIssue model.key role Nothing model.developerName)
        Reviewer ->
          ({ model
            | isBeingUpdated = True
            , reviewerName = Nothing
          }, effectUpdateIssue model.key role Nothing model.reviewerName)

    UpdateProcessed role maybeNewName maybePreviousName maybeResult ->
      case maybeResult of
        Just "ok" ->
          ({ model | isBeingUpdated = False }, Effects.none)
        _ ->
          ({ model
            | isBeingUpdated = False
          }, Effects.none)

-- VIEW

view : Signal.Address Action -> Model -> List String -> Html
view address model teamMemberNames =
  let
    options = List.map (\n -> (n, n)) teamMemberNames
  in
    tr [ class "issue-item", key model.key ]
      [ td []
        [ strong [] [ text model.key ]
        , span [ class "issue-item__summary" ] [ text model.summary ]
        ]
      , td [] [ text <| toString model.estimate ]
      , td
        []
        [ Mui.selectBox (Signal.forwardTo address (Assign Developer)) "None" options model.developerName ]
      , td
        []
        [ Mui.selectBox (Signal.forwardTo address (Assign Reviewer)) "None" options model.reviewerName ]
      ]

-- EFFECTS

effectUpdateIssue : String -> Role -> Maybe String -> Maybe String -> Effects Action
effectUpdateIssue key role maybeNewName maybePreviousName =
  let
    url_base = "/api/issues/" ++ key
    url = Http.url url_base []
    roleString = case role of
      Developer -> "developer"
      Reviewer -> "reviewer"
    body = Http.multipart
      [ Http.stringData roleString (Maybe.withDefault "" maybeNewName) ]
  in
    -- Http.post : Decoder value -> String -> Body -> Task Error value
    Http.post Json.Decode.string url body
      |> Task.toMaybe
      |> Task.map (UpdateProcessed role maybeNewName maybePreviousName)
      |> Effects.task
