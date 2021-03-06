{-# LANGUAGE DeriveDataTypeable #-}
{-# LANGUAGE TypeFamilies #-}

module ViewModels.WorkspaceViewModel where

import Graphics.QML as QML
import qualified Data.Text.Encoding as T
import qualified Data.Text as T
import Data.Typeable
import Data.Proxy
import qualified Data.List as L (nub)
import Control.Concurrent.MVar
import Control.Monad (when)

import Lib

import ViewModels.DeviceViewModel
import Andromeda.Simulator
import Andromeda.Assets.SpaceshipSample

data WorkspaceVM = SimulatorWorkspaceVM
  { _workspaceSimulatorRuntime :: SimulatorRuntime
  , _workspaceSimDevices :: MVar [ObjRef DeviceVM]
  }

data DevicesChanged deriving Typeable

instance SignalKeyClass DevicesChanged where
  type SignalParams DevicesChanged = IO ()

instance DefaultClass WorkspaceVM where
  classMembers = [ defMethod' "vmToggleSimulation" toggleSimulation
                 , defPropertySigRO "vmDevices" (Proxy :: Proxy DevicesChanged) getDevices']
    where
        getDevices' :: ObjRef WorkspaceVM -> IO [ObjRef DeviceVM]
        getDevices' = readMVar . _workspaceSimDevices . fromObjRef

runSimulation (SimulatorRuntime handleVar pipe simModel) = do
  h <- startSimulation pipe process simModel
  r1 <- sendRequest pipe (setGen1Act boostersNozzle1T)
  r2 <- sendRequest pipe (setGen2Act boostersNozzle2T)
  let isOk = L.nub [r1, r2] == [Ok]
  if isOk then putMVar handleVar h >> print "Simulation started."
          else print "Simulation failed."
  return isOk

toggleSimulation :: ObjRef WorkspaceVM -> Bool -> IO ()
toggleSimulation objRef True = do
  let runtime = _workspaceSimulatorRuntime . fromObjRef $ objRef
  let mvDevices = _workspaceSimDevices . fromObjRef $ objRef
  isOk <- runSimulation runtime
  if isOk then do
              ds <- getDevices runtime
              dVms <- mapM createDeviceVM ds
              _ <- swapMVar mvDevices dVms
              fireSignal (Proxy :: Proxy DevicesChanged) objRef
              print $ "Devices created: " ++ show (length dVms)
          else print "Toggle sim failed."
toggleSimulation objRef False = do
  let runtime = _workspaceSimulatorRuntime . fromObjRef $ objRef
  terminateSimulation runtime
  print "Simulation stopped."

createSimulatorWorkspace = do
  print "Loading sample spaceship network..."
  simulatorRuntime <- makeSimulatorRuntime networkDef
  devices <- newMVar []
  let workspace = SimulatorWorkspaceVM simulatorRuntime devices
  let workspaceView = T.pack "SimulatorWorkspaceView.qml"
  return (workspaceView, workspace)
