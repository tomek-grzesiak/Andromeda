module Andromeda.Hardware.Network where

import Andromeda.Common
import Andromeda.Calculations
import Andromeda.Hardware.Parameter
import Andromeda.Hardware.Description
import Andromeda.Hardware.HDL

import qualified Data.Vector as V
import qualified Data.Map as M
import qualified Data.ByteString.Char8 as BS


-- TODO: tagged:
-- type ValueSource tag = (PhysicalAddress, ComponentIndex)
type ValueSource = (PhysicalAddress, ComponentIndex)


