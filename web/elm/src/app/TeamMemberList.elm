module TeamMemberList where

import Html exposing (..)
import Html.Attributes exposing (class, style, title)
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
  , isShowingUsersWithZeroCapacity : Bool
  }

init : List String -> Model
init names =
  let
    teamMembers = List.map (\name -> TeamMember.init name 0) names
      |> indexList 0
  in
    { teamMembers = teamMembers
    , capacityEditionEnabled = False
    , isShowingUsersWithZeroCapacity = True
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
  | ShowUsersWithZeroCapacity
  | HideUsersWithZeroCapacity

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
    ShowUsersWithZeroCapacity ->
      { model | isShowingUsersWithZeroCapacity = True }
    HideUsersWithZeroCapacity ->
      { model | isShowingUsersWithZeroCapacity = False }

-- Update the assignments of the team members in the list.
-- First reset all assignments (all team members are reset
-- to 0 of assignment). Then, all assignments passed in
-- namedAssignmentsList are processed.
updateAssignments : List (String, List TeamMember.Assignment) -> Model -> Model
updateAssignments namedAssignmentsList model =
  let
    -- resetAssignments : Model -> Model
    -- resetAssignments model =
    --   List.map (\(_, tm) -> TeamMember.updateAssignmentReset tm) model.teamMembers
    applyNamedAssignmentsList : TeamMember.Model -> TeamMember.Model
    applyNamedAssignmentsList teamMemberModel =
      let
        maybeMatchingAssignments =
          List.filter (\(name, _) -> name == TeamMember.getName teamMemberModel) namedAssignmentsList
            |> List.head
      in
        case maybeMatchingAssignments of
          Nothing -> TeamMember.updateAssignmentsReset teamMemberModel
          Just (name, assignments) ->
            TeamMember.updateAssignments teamMemberModel assignments
  in
    { model |
      teamMembers =
        List.map (\(id, tm) -> (id, applyNamedAssignmentsList tm)) model.teamMembers }

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
      [ text "Add team member" ]
    showedTeamMembers = case model.isShowingUsersWithZeroCapacity of
      True  -> model.teamMembers
      False -> List.filter (\(_, tm) -> TeamMember.getCapacity tm > 0) model.teamMembers
    viewList = List.concatMap (viewTeamMember address maxCapacity) showedTeamMembers
    headerRow = tr []
      [ th [ title "Team member" ] [ text "" ]
      , th [ title "Capacity" ] [ text "" ]
      , th [ title "Assigned" ] [ text "A" ]
      , th [ title "Remaining" ] [ text "R" ]
      ]
  in
    div []
      [ table [ class "team-members-list" ] ([ headerRow ] ++ viewList)
      , div [ class "team-members-list__buttons" ]
        [ viewButtonAdd
        , viewButtonToggleCapacityEdition address model
        , viewButtonToggleShowingTeamMembersWithZeroCapacity address model
        ]
      ]

viewButtonToggleCapacityEdition : Signal.Address Action -> Model -> Html
viewButtonToggleCapacityEdition address model =
  let
    buildButton action str = button
      [ class "mui-btn mui-btn--small", onClick address action ]
      [ text str ]
  in
    case model.capacityEditionEnabled of
      True  -> buildButton DisableCapacityEdition "Done editing capacities"
      False -> buildButton EnableCapacityEdition "Edit capacities"

viewButtonToggleShowingTeamMembersWithZeroCapacity : Signal.Address Action -> Model -> Html
viewButtonToggleShowingTeamMembersWithZeroCapacity address model =
  let
    buildButton action str = button
      [ class "mui-btn mui-btn--small", onClick address action ]
      [ text str ]
  in
    case model.isShowingUsersWithZeroCapacity of
      True  -> buildButton HideUsersWithZeroCapacity "Hide users with no capacity"
      False -> buildButton ShowUsersWithZeroCapacity "Show all users"

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
