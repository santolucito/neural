{-# OPTIONS_HADDOCK show-extensions #-}

{-# LANGUAGE BangPatterns #-}
{-# LANGUAGE FlexibleContexts #-}

module Numeric.Neural.Genetic
    ( geneticTrain
    ) where

import           Data.MyPrelude
import           Numeric.Neural.Model
import           Numeric.Neural.Normalization
import           Numeric.Neural.Pipes
import           Data.Utils.Cache
import           Data.Utils.Random            (takeR)
import           Pipes
import           Pipes.Core
import qualified Pipes.Prelude as P
import Data.List

-- | Just try random weights and always take the best one
--
geneticTrain :: 
       ((Model f g a b c) -> IO Double) -- ^ run the model and get cost
       -> Int                            -- ^ generation size
       -> Int                            -- ^ number of spawn based on previous best
       -> (Double,(Model f g a b c))
       -> Producer (TS f g a b c) IO ()      -- produces better and better models (hopefully)
geneticTrain f gs ss ts = loop ts 
   where
    loop oldBest = do
       randomGen <- mapM (lift. evalRandIO. modelR) (replicate (gs-ss) (snd oldBest))
       improvedGen <- mapM (lift. evalRandIO. modelG) (replicate ss (snd oldBest))
       let newGen = randomGen++improvedGen
       costs <- mapM (lift. f) newGen
       let cs = zip costs newGen
       let bestModel = maximumBy (\x y -> compare (fst x) (fst y)) (oldBest:cs)
       bestModel `deepseq` yield TS
            { tsModel      = snd bestModel
            , tsGeneration = 1 --not sure this is used anyway
            , tsEta        = 0 --also dont think this matters
            , tsBatchError = fst bestModel
            }
       loop $ bestModel
    
