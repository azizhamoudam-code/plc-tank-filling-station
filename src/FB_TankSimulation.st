FUNCTION_BLOCK FB_TankSimulation

VAR_INPUT
    xInletValve       : BOOL;
    xDrainValve       : BOOL;
    tSimCycleTime     : TIME := T#100MS;
    fFillStepPercent  : REAL := 1.0;
    fDrainStepPercent : REAL := 1.5;
END_VAR

VAR_OUTPUT
    fLevelPercent     : REAL := 0.0;
END_VAR

VAR
    fbSimTick         : TON;
END_VAR

fbSimTick(IN := NOT fbSimTick.Q, PT := tSimCycleTime);

IF fbSimTick.Q THEN
    IF xInletValve AND NOT xDrainValve THEN
        fLevelPercent := fLevelPercent + fFillStepPercent;
    ELSIF xDrainValve AND NOT xInletValve THEN
        fLevelPercent := fLevelPercent - fDrainStepPercent;
    END_IF;
END_IF;

IF fLevelPercent > 100.0 THEN
    fLevelPercent := 100.0;
ELSIF fLevelPercent < 0.0 THEN
    fLevelPercent := 0.0;
END_IF;
END_FUNCTION_BLOCK
