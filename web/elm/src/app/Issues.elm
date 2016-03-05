module Issues where

import Set exposing (Set)

import Issue

teamMemberNames : List Issue.Model -> Set String
teamMemberNames issues =
  let
    insertMaybeName : Maybe String -> Set String -> Set String
    insertMaybeName maybeName names =
      case maybeName of
        Nothing -> names
        Just name -> Set.insert name names
  in
    case issues of
      head :: tail ->
        teamMemberNames tail
          |> insertMaybeName head.developerName
          |> insertMaybeName head.reviewerName
      _ -> Set.empty
