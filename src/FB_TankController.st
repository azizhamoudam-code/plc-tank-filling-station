FUNCTION_BLOCK FB_TankController

VAR_INPUT
    xStart          : BOOL;
    xReset          : BOOL;
    xEmergencyStop  : BOOL;
    fLevelPercent   : REAL;
    fFillSetpoint   : REAL := 80.0;
    fDrainSetpoint  : REAL := 10.0;
    tMixTime        : TIME := T#10S;
    tFillTimeout    : TIME := T#30S;
    tDrainTimeout   : TIME := T#30S;
END_VAR

VAR_OUTPUT
    xInletValve     : BOOL;
    xDrainValve     : BOOL;
    xMixer          : BOOL;
    eState          : E_TankState := E_TankState.IDLE;
    nErrorCode      : INT;
    xFault          : BOOL;
END_VAR

VAR CONSTANT
    ERR_NONE           : INT := 0;
    ERR_FILL_TIMEOUT   : INT := 1;
    ERR_DRAIN_TIMEOUT  : INT := 2;
    ERR_EMERGENCY_STOP : INT := 3;
    ERR_UNKNOWN_STATE  : INT := 4;
END_VAR

VAR
    fbTrigStart     : R_TRIG;
    fbTrigReset     : R_TRIG;
    fbFillTimeout   : TON;
    fbDrainTimeout  : TON;
    fbMixTimer      : TON;
    xInletValveCmd  : BOOL;
    xDrainValveCmd  : BOOL;
    xMixerCmd       : BOOL;
END_VAR

// Rising edge of the two push-buttons
fbTrigStart(CLK := xStart);
fbTrigReset(CLK := xReset);

// 1) EMERGENCY STOP - highest priority, always wins
IF xEmergencyStop THEN
    eState         := E_TankState.FAULT;
    nErrorCode     := ERR_EMERGENCY_STOP;
    xInletValveCmd := FALSE;
    xDrainValveCmd := FALSE;
    xMixerCmd      := FALSE;
ELSE
    // 2) NORMAL STATE MACHINE (see docs/state_diagram.md)
    CASE eState OF
        E_TankState.IDLE:
            xInletValveCmd := FALSE;
            xDrainValveCmd := FALSE;
            xMixerCmd      := FALSE;
            nErrorCode     := ERR_NONE;

            IF fbTrigStart.Q THEN
                eState := E_TankState.FILLING;
            END_IF;

        E_TankState.FILLING:
            xInletValveCmd := TRUE;
            xDrainValveCmd := FALSE;
            xMixerCmd      := FALSE;

            IF fLevelPercent >= fFillSetpoint THEN
                xInletValveCmd := FALSE;
                eState         := E_TankState.MIXING;
            ELSIF fbFillTimeout.Q THEN
                nErrorCode := ERR_FILL_TIMEOUT;
                eState     := E_TankState.FAULT;
            END_IF;

        E_TankState.MIXING:
            xInletValveCmd := FALSE;
            xDrainValveCmd := FALSE;
            xMixerCmd      := TRUE;

            IF fbMixTimer.Q THEN
                xMixerCmd := FALSE;
                eState    := E_TankState.DRAINING;
            END_IF;

        E_TankState.DRAINING:
            xInletValveCmd := FALSE;
            xDrainValveCmd := TRUE;
            xMixerCmd      := FALSE;

            IF fLevelPercent <= fDrainSetpoint THEN
                xDrainValveCmd := FALSE;
                eState         := E_TankState.COMPLETE;
            ELSIF fbDrainTimeout.Q THEN
                nErrorCode := ERR_DRAIN_TIMEOUT;
                eState     := E_TankState.FAULT;
            END_IF;

        E_TankState.COMPLETE:
            xInletValveCmd := FALSE;
            xDrainValveCmd := FALSE;
            xMixerCmd      := FALSE;

            IF fbTrigReset.Q THEN
                eState := E_TankState.IDLE;
            END_IF;

        E_TankState.FAULT:
            xInletValveCmd := FALSE;
            xDrainValveCmd := FALSE;
            xMixerCmd      := FALSE;

            IF fbTrigReset.Q AND NOT xEmergencyStop THEN
                nErrorCode := ERR_NONE;
                eState     := E_TankState.IDLE;
            END_IF;
    ELSE
        eState     := E_TankState.FAULT;
        nErrorCode := ERR_UNKNOWN_STATE;
    END_CASE;
END_IF;

// Each timer runs only in its own state, so it resets on leaving it.
fbFillTimeout (IN := (eState = E_TankState.FILLING),  PT := tFillTimeout);
fbDrainTimeout(IN := (eState = E_TankState.DRAINING), PT := tDrainTimeout);
fbMixTimer    (IN := (eState = E_TankState.MIXING),   PT := tMixTime);

// 3) HARD SAFETY INTERLOCKS - applied last, directly on the outputs
xInletValve := xInletValveCmd AND NOT xDrainValveCmd;
xDrainValve := xDrainValveCmd AND NOT xInletValveCmd;
xMixer      := xMixerCmd AND (fLevelPercent >= fFillSetpoint);
xFault      := (eState = E_TankState.FAULT);
END_FUNCTION_BLOCK
