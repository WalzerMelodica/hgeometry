module Algorithms.Geometry.ConvexHull.Helpers where

import           Algorithms.Geometry.ConvexHull.Types
import           Control.Monad.Trans
import           Data.Geometry.Point
import           Data.IndexedDoublyLinkedList
import qualified Data.List as List
import           Data.Ord (comparing)

import Debug.Trace

----------------------------------------------------------------------------------
-- * Convienience Functions in the Hull Monad.

pointAt :: Index -> HullM s r (Point 3 r)
pointAt = valueAt

pointAt' :: Index -> Simulation s r (Point 3 r)
pointAt' = lift . pointAt

atTime     :: Num r => r -> Index -> HullM s r (Point 2 r)
atTime t i = atTime' t <$> pointAt i

-- | Computes the position of the given point at time t
atTime'                  :: Num r => r -> Point 3 r -> Point 2 r
atTime' t (Point3 x y z) = Point2 x (z - t*y)


-- | Applies the actual event, mutating the current representation of the hulls.
applyEvent' :: EventKind -> HullM s r ()
applyEvent' = \case
  InsertAfter i j  -> insertAfter i j
  InsertBefore i h -> insertBefore i h
  Delete j         -> delete j

applyEvent   :: (Show r) => Event r -> HullM s r ()
applyEvent e = applyEvent' $ traceShow ("applyEvent ",e) (eventKind e)


--------------------------------------------------------------------------------
-- * Generic Helpers

minimumOn   :: Ord b => (a -> b) -> [a] -> Maybe a
minimumOn f = \case
    [] -> Nothing
    xs -> Just $ List.minimumBy (comparing f) xs



takeWhileM   :: Monad m => (a -> m Bool) -> [a] -> m [a]
takeWhileM p = go
  where
    go = \case
      []      -> pure []
      (x:xs) -> do b <- p x
                   if b then (x:) <$> go xs else pure []
