-- | This module contains primitive modifiers for lists and 'String's to be
-- filled or fitted to a specific length.
module Text.Layout.Table.PrimMod
    ( -- * Cut marks
      CutMarkSpec
    , cutMark
    , singleCutMark
    , noCutMark
    , ellipsisCutMark

      -- * String-related tools
    , spaces
    , fillLeft'
    , fillLeft
    , fillRight
    , fillCenter'
    , fillCenter
    , fitRightWith
    , fitLeftWith
    , fitCenterWith
    , applyMarkLeftWith
    , applyMarkRightWith

      -- * List-related tools
    , fillStart'
    , fillStart
    , fillEnd
    , fillBoth'
    , fillBoth
    )
    where

import Data.Default.Class

-- | Specifies how the place looks where a 'String' has been cut. Note that the
-- cut mark may be cut itself, to fit into a column.
data CutMarkSpec = CutMarkSpec
                 { leftMark  :: String
                 , rightMark :: String
                 }

instance Default CutMarkSpec where
    def = ellipsisCutMark

instance Show CutMarkSpec where
    show (CutMarkSpec l r) = "cutMark " ++ show l ++ ' ' : show (reverse r)

-- | Display custom characters on a cut.
cutMark :: String -> String -> CutMarkSpec
cutMark l r = CutMarkSpec l (reverse r)

-- | Use the same cut mark for left and right.
singleCutMark :: String -> CutMarkSpec
singleCutMark l = cutMark l (reverse l)

-- | Don't use a cut mark.
noCutMark :: CutMarkSpec
noCutMark = singleCutMark ""

-- | A single unicode character showing three dots is used as cut mark.
ellipsisCutMark :: CutMarkSpec
ellipsisCutMark = singleCutMark "…"

spaces :: Int -> String
spaces = flip replicate ' '

fillStart' :: a -> Int -> Int -> [a] -> [a]
fillStart' x i lenL l = replicate (i - lenL) x ++ l

fillStart :: a -> Int -> [a] -> [a]
fillStart x i l = fillStart' x i (length l) l

fillEnd :: a -> Int -> [a] -> [a]
fillEnd x i l = take i $ l ++ repeat x

fillBoth' :: a -> Int -> Int -> [a] -> [a]
fillBoth' x i lenL l = 
    -- Puts more on the beginning if odd.
    filler q ++ l ++ filler (q + r)
  where
    filler  = flip replicate x
    missing = i - lenL
    (q, r)  = missing `divMod` 2

fillBoth :: a -> Int -> [a] -> [a]
fillBoth x i l = fillBoth' x i (length l) l

fillLeft' :: Int -> Int -> String -> String
fillLeft' = fillStart' ' '

-- | Fill on the left until the 'String' has the desired length.
fillLeft :: Int -> String -> String
fillLeft = fillStart ' '

-- | Fill on the right until the 'String' has the desired length.
fillRight :: Int -> String -> String
fillRight = fillEnd ' '

fillCenter' :: Int -> Int -> String -> String
fillCenter' = fillBoth' ' '

-- | Fill on both sides equally until the 'String' has the desired length.
fillCenter :: Int -> String -> String
fillCenter = fillBoth ' '

-- | Fits to the given length by either trimming or filling it to the right.
fitRightWith :: CutMarkSpec -> Int -> String -> String
fitRightWith cms i s =
    if length s <= i
    then fillRight i s
    else applyMarkRightWith cms $ take i s
         --take i $ take (i - mLen) s ++ take mLen m

-- | Fits to the given length by either trimming or filling it to the right.
fitLeftWith :: CutMarkSpec -> Int -> String -> String
fitLeftWith cms i s =
    if lenS <= i
    then fillLeft' i lenS s
    else applyMarkLeftWith cms $ drop (lenS - i) s
  where
    lenS = length s

-- | Fits to the given length by either trimming or filling it on both sides,
-- but when only 1 character should be trimmed it will trim left.
fitCenterWith :: CutMarkSpec -> Int -> String -> String
fitCenterWith cms i s             = 
    if diff >= 0
    then fillCenter' i lenS s
    else case splitAt halfLenS s of
        (ls, rs) -> addMarks $ drop (halfLenS - halfI) ls ++ take (halfI + r) rs
  where
    addMarks   = applyMarkLeftWith cms . if diff == (-1) then id else applyMarkRightWith cms
    diff       = i - lenS
    lenS       = length s
    halfLenS   = lenS `div` 2
    (halfI, r) = i `divMod` 2

-- | Applies a 'CutMarkSpec' to the left of a 'String', while preserving the length.
applyMarkLeftWith :: CutMarkSpec -> String -> String
applyMarkLeftWith cms = applyMarkLeftBy leftMark cms

-- | Applies a 'CutMarkSpec' to the right of a 'String', while preserving the length.
applyMarkRightWith :: CutMarkSpec -> String -> String
applyMarkRightWith cms = reverse . applyMarkLeftBy rightMark cms . reverse

applyMarkLeftBy :: (a -> String) -> a -> String -> String
applyMarkLeftBy f v = zipWith ($) $ map const (f v) ++ repeat id
