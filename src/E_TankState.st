{attribute 'qualified_only'}
{attribute 'strict'}
TYPE E_TankState :
(
    IDLE     := 0,
    FILLING  := 1,
    MIXING   := 2,
    DRAINING := 3,
    COMPLETE := 4,
    FAULT    := 5
);
END_TYPE
