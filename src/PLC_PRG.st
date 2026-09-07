PROGRAM PLC_PRG

VAR
    xStart          : BOOL;
    xReset          : BOOL;
    xEmergencyStop  : BOOL;

    fbTank          : FB_TankController;
    fbSimulation    : FB_TankSimulation;
END_VAR

fbTank(
    xStart         := xStart,
    xReset         := xReset,
    xEmergencyStop := xEmergencyStop,
    fLevelPercent  := fbSimulation.fLevelPercent
);

fbSimulation(
    xInletValve := fbTank.xInletValve,
    xDrainValve := fbTank.xDrainValve
);
END_PROGRAM
