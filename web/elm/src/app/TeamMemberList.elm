module TeamMemberList where

import Html exposing (..)
import Html.Attributes exposing (class, style, draggable)
import Html.Events exposing (onClick)
import List
import ListFunctions exposing (indexList)

import IndexedList
import ProgressBar
import TeamMember


-- MODEL

type alias ID = Int
type alias Model = List (ID, TeamMember.Model)

init : List String -> Model
init names =
  List.map (\name -> TeamMember.init name 0) names
    |> indexList 0

getNames : Model -> List String
getNames model =
  model
    |> List.map (\(id, tm) -> tm)
    |> List.map (\tm -> TeamMember.getName tm)

getMaxCapacity : Model -> Int
getMaxCapacity model =
  List.map (\(id, tm) -> TeamMember.getCapacity tm) model
    |> List.maximum
    |> Maybe.withDefault 0


-- UPDATE

type Action
  = Add
  | Remove ID
  | Modify ID TeamMember.Action

update : Action -> Model -> Model
update action model =
  case action of
    Add -> updateAddTeamMemberWithName model "Unknown"
    Remove id -> model
    Modify id teamMemberAction ->
      let
        updateTeamMember : (ID, TeamMember.Model) -> (ID, TeamMember.Model)
        updateTeamMember (teamMemberID, teamMemberModel) =
          if teamMemberID == id then
            (teamMemberID, TeamMember.update teamMemberAction teamMemberModel)
          else
            (teamMemberID, teamMemberModel)
      in
        List.map updateTeamMember model

updateAssignments : List (String, List TeamMember.Assignment) -> Model -> Model
updateAssignments namedAssignmentsList model =
  let
    applyNamedAssignmentsList : TeamMember.Model -> TeamMember.Model
    applyNamedAssignmentsList teamMemberModel =
      let
        maybeMatchingAssignments =
          List.filter (\(name, _) -> name == TeamMember.getName teamMemberModel) namedAssignmentsList
            |> List.head
      in
        case maybeMatchingAssignments of
          Nothing -> teamMemberModel
          Just (name, assignments) -> TeamMember.updateAssignments teamMemberModel assignments
  in
    List.map (\(id, tm) -> (id, applyNamedAssignmentsList tm)) model

-- Adds a new team member. No change if a team member with the specified
-- name is already present.
updateAddTeamMemberWithName : Model -> String -> Model
updateAddTeamMemberWithName model name =
  case List.member name (getNames model) of
    True -> model
    False -> IndexedList.append model (TeamMember.init name 0)

-- Adds several new team members according to the specified names.
updateAddTeamMemberWithNames : List String -> Model -> Model
updateAddTeamMemberWithNames names model =
  case names of
    [] -> model
    name :: otherNames ->
      updateAddTeamMemberWithName model name
        |> updateAddTeamMemberWithNames otherNames


-- VIEW

view : Signal.Address Action -> Model -> Html
view address model =
  let
    maxCapacity = toFloat <| getMaxCapacity model
    viewButtonAdd = button
      [ class "mui-btn mui-btn--primary", onClick address Add ]
      [ text "Add" ]
    viewList = viewTeamMemberList address model maxCapacity
  in
    div []
      [ table [ class "team-members-list" ] viewList
      , viewButtonAdd
      ]

viewTeamMemberList : Signal.Address Action -> Model -> Float -> List Html
viewTeamMemberList address model maxCapacity =
  List.concatMap (viewTeamMember address maxCapacity) model

viewTeamMember : Signal.Address Action -> Float -> (ID, TeamMember.Model) -> List Html
viewTeamMember address maxCapacity (id, tm) =
  let
    assigned = TeamMember.getAssigned tm
    capacity = TeamMember.getCapacity tm |> toFloat
    remainingRatio = (capacity - assigned) / capacity
  in
    [ TeamMember.view (Signal.forwardTo address (Modify id)) tm
    , ProgressBar.view remainingRatio
    ]
