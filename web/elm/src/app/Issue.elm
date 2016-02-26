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
  , estimate : Int
  , developerName : Maybe String
  , reviewerName : Maybe String
  , isBeingUpdated : Bool
  , previousDeveloperName : Maybe String
  , previousReviewerName : Maybe String
  }

init : String -> String -> Int -> Maybe String -> Maybe String -> Model
init key summary estimate maybeDeveloperName maybeReviewerName =
  { key = key
  , summary = summary
  , estimate = estimate
  , developerName = maybeDeveloperName
  , reviewerName = maybeReviewerName
  , isBeingUpdated = False
  , previousDeveloperName = Nothing
  , previousReviewerName = Nothing
  }


-- UPDATE

type Action
  = Assign Role Mui.Action
  | Unassign Role
  | Updated (Maybe String)

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
              , previousDeveloperName = model.developerName
              , previousReviewerName = model.reviewerName
            }, effectUpdateIssue model)
          Reviewer ->
            ({ model
              | isBeingUpdated = True
              , reviewerName = selectedTeamMemberName
              , previousDeveloperName = model.developerName
              , previousReviewerName = model.reviewerName
            }, effectUpdateIssue model)

    Unassign role ->
      case role of
        Developer ->
          ({ model
            | isBeingUpdated = True
            , developerName = Nothing
            , previousDeveloperName = model.developerName
            , previousReviewerName = model.reviewerName
          }, effectUpdateIssue model)
        Reviewer ->
          ({ model
            | isBeingUpdated = True
            , reviewerName = Nothing
            , previousDeveloperName = model.developerName
            , previousReviewerName = model.reviewerName
          }, effectUpdateIssue model)

    Updated maybeResult ->
      case maybeResult of
        Just result ->
          ({ model | isBeingUpdated = False }, Effects.none)
        Nothing ->
          ({ model
            | isBeingUpdated = False
            , developerName = model.previousDeveloperName
            , reviewerName = model.previousReviewerName
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

effectUpdateIssue : Model -> Effects Action
effectUpdateIssue model =
  let
    url_base = "/api/issues/" ++ model.key
    url = Http.url url_base []
    body = Http.multipart
      [ Http.stringData "developer" (Maybe.withDefault "" model.developerName)
      , Http.stringData "reviewer" (Maybe.withDefault "" model.reviewerName)
      ]
  in
    -- Http.post : Decoder value -> String -> Body -> Task Error value
    Http.post Json.Decode.string url body
      |> Task.toMaybe
      |> Task.map Updated
      |> Effects.task
