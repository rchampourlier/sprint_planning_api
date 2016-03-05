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
type alias Model =
  { teamMembers : List (ID, TeamMember.Model)
  , capacityEditionEnabled : Bool
  }

init : List String -> Model
init names =
  let
    teamMembers = List.map (\name -> TeamMember.init name 0) names
      |> indexList 0
  in
    { teamMembers = teamMembers
    , capacityEditionEnabled = False
    }

getTeamMemberNames : Model -> List String
getTeamMemberNames model =
  model.teamMembers
    |> List.map (\(id, tm) -> tm)
    |> List.map (\tm -> TeamMember.getName tm)

getMaxCapacity : Model -> Int
getMaxCapacity model =
  List.map (\(id, tm) -> TeamMember.getCapacity tm) model.teamMembers
    |> List.maximum
    |> Maybe.withDefault 0


-- UPDATE

type Action
  = Add
  | Modify ID TeamMember.Action
  | EnableCapacityEdition
  | DisableCapacityEdition

update : Action -> Model -> Model
update action model =
  case action of
    Add -> updateAddTeamMemberWithName model "Unknown"
    Modify id teamMemberAction ->
      let
        updateTeamMember : (ID, TeamMember.Model) -> (ID, TeamMember.Model)
        updateTeamMember (teamMemberID, teamMemberModel) =
          if teamMemberID == id then
            (teamMemberID, TeamMember.update teamMemberAction teamMemberModel)
          else
            (teamMemberID, teamMemberModel)
      in
        { model | teamMembers = List.map updateTeamMember model.teamMembers }
    EnableCapacityEdition ->
      { model
        | teamMembers = List.map (\(id, tm) -> (id, TeamMember.updateEnableCapacityEdition tm)) model.teamMembers
        , capacityEditionEnabled = True
      }
    DisableCapacityEdition ->
      { model
        | teamMembers = List.map (\(id, tm) -> (id, TeamMember.updateDisableCapacityEdition tm)) model.teamMembers
        , capacityEditionEnabled = False
      }

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
    { model | teamMembers = List.map (\(id, tm) -> (id, applyNamedAssignmentsList tm)) model.teamMembers }

-- Adds a new team member. No change if a team member with the specified
-- name is already present.
updateAddTeamMemberWithName : Model -> String -> Model
updateAddTeamMemberWithName model name =
  case List.member name (getTeamMemberNames model) of
    True -> model
    False -> { model | teamMembers = IndexedList.append model.teamMembers (TeamMember.init name 0) }

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
    buttonToggleCapacityEditionAction = case model.capacityEditionEnabled of
      True -> DisableCapacityEdition
      False -> EnableCapacityEdition
    buttonToggleCapacityEditionText = case model.capacityEditionEnabled of
      True -> "Done"
      False -> "Edit capacities"
    viewButtonToggleCapacityEdition = button
      [ class "mui-btn", onClick address buttonToggleCapacityEditionAction ]
      [ text buttonToggleCapacityEditionText ]
    viewList = List.concatMap (viewTeamMember address maxCapacity) model.teamMembers
  in
    div []
      [ table [ class "team-members-list" ] viewList
      , viewButtonAdd
      , viewButtonToggleCapacityEdition
      ]

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
