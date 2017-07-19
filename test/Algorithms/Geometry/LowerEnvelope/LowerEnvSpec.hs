{-# LANGUAGE OverloadedStrings #-}
module Algorithms.Geometry.LowerEnvelope.LowerEnvSpec where

import Data.Semigroup
import Data.Maybe(mapMaybe)
import Util
import Data.List.NonEmpty(NonEmpty(..))
import qualified Data.List.NonEmpty as NonEmpty
import Data.Ext
import Control.Lens
import Data.Geometry
import Data.Geometry.Line
import Frames.CoRec
import Test.Hspec
import Data.Ratio
import Data.Geometry.Ipe
import Data.Proxy
import qualified Algorithms.Geometry.LowerEnvelope.DualCH as DualCH
-- import Algorithms.Geometry.LowerEnvelope.Types

spec :: Spec
spec = testCases "test/Algorithms/Geometry/LowerEnvelope/manual.ipe"

testCases    :: FilePath -> Spec
testCases fp = (runIO $ readInput fp) >>= \case
    Left e    -> it "reading Smallest enclosing disk file" $
                   expectationFailure $ "Failed to read ipe file " ++ show e
    Right tcs -> mapM_ toSpec tcs




data TestCase r = TestCase { _lines    :: NonEmpty (Line 2 r :+ ())
                           , _color    :: Maybe IpeColor
                           , _solution :: [Point 2 r]
                           }
                  deriving (Show,Eq)


readInput    :: FilePath -> IO (Either ConversionError [TestCase Rational])
readInput fp = fmap f <$> readSinglePageFile fp
  where
    f page = [ let c = lookup' $ NonEmpty.head lSet
               in TestCase ((\l -> l^.core.to supportingLine :+ ()) <$> lSet)
                           c
                           (solutionOf c)
             | lSet <- mapMaybe NonEmpty.nonEmpty $ byStrokeColour segs
             ]
      where
        segs :: [LineSegment 2 () Rational :+ IpeAttributes Path Rational]
        segs = page^..content.traverse._withAttrs _IpePath _asLineSegment
        pts  = page^..content.traverse._IpeUse

        solutionOf c = [ p^.core.symbolPoint
                       | p <- pts, lookup' p == c
                       ]



lookup' (_ :+ ats) = lookupAttr (Proxy :: Proxy Stroke) ats



toSpec                    :: (Fractional r, Ord r, Show r) => TestCase r -> Spec
toSpec (TestCase ls c sol) = it ("testing the " <> show c <> " set") $
  (map (^.core) . DualCH.vertices . DualCH.lowerEnvelope $ ls) `shouldBe` sol
