module MathUtils where

-- Rounds the specified float number to the specified
-- number of decimals.
floatRound : Float -> Int -> Float
floatRound value decimals =
  let floatDecimals = toFloat decimals
  in (toFloat (round (value * 10 * floatDecimals))) / (floatDecimals * (toFloat 10))
