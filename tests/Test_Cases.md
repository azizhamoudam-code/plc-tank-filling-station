# Test cases

Run in CODESYS simulation, using a Watch List to set the buttons and read the
outputs. The simulation was slowed down for the mid-cycle tests. That is an
online change only, the values in `src/` are unchanged.

| # | Test | Result | eState | nErrorCode |
|---|---|---|---|---|
| 1 | Normal full cycle | ok | IDLE after reset | 0 |
| 2 | E-Stop while FILLING | ok | FAULT | 3 |
| 3 | E-Stop while MIXING | ok | FAULT | 3 |
| 4 | E-Stop while DRAINING | ok | FAULT | 3 |
| 5 | Reset while E-Stop still pressed | ok | stays FAULT | 3 |
| 6 | Reset after E-Stop released | ok | IDLE | 0 |
| 7 | Fill timeout | ok | FAULT | 1 |
| 8 | Drain timeout | ok | FAULT | 2 |
| 9 | Mixer interlock | ok | MIXING, mixer off | 0 |
| 10 | Both valves never open together | not reproducible by forcing, see note | - | - |
| 11 | Reset from COMPLETE | ok | IDLE | 0 |
| 12 | Reset during a batch | ok | no change | no change |

Screenshots for each are in `docs/screenshots/`.

## Notes

**2 to 4.** Every time the state went to FAULT with code 3 and the running
output switched off straight away. Test 2 was caught at about 18%, which is the
screenshot. Tests 3 and 4 behaved the same way at their own levels.

**7.** I did not shorten the timeout for this one. Because the simulation was
slowed to 500 ms per tick, filling took longer than the normal 30 s
`tFillTimeout`, so it tripped by itself at 64%, below the 80% setpoint.

**8.** Draining normally reaches 10% in a few seconds, so the timeout never
fires by itself. I forced `fLevelPercent` to 85 so the level could never get
there, set `tDrainTimeout` to 5 s, and ran a batch. FAULT with code 2, drain
valve off.

**9.** With the mixer running at 80% I forced `fLevelPercent` down to 50. The
mixer went off immediately but `eState` stayed MIXING. That is the point of the
test: the interlock is on the output, not in the state machine.

**10. Not reproducible by forcing.**

I tried to provoke it by forcing `xDrainValveCmd` TRUE during FILLING, expecting
both valve outputs to go FALSE. They did not, `xInletValve` stayed TRUE.

The scan order explains it. The CASE block writes `xDrainValveCmd := FALSE` in
the FILLING branch, and the interlock lines read it further down in the same
scan. A force is only re-applied at the task boundaries, so the state machine
overwrites it before the interlock ever sees it. The Watch List still showed
TRUE because that is the value after the scan finished, not the value the
interlock read.

So a force only works on a variable the code reads but never writes.
`fLevelPercent` in test 9 is a VAR_INPUT and works. `xDrainValveCmd` is written
every scan and does not.

Proving it at runtime needs a breakpoint on the interlock line and a write while
execution is halted.

## A bug I found

The first build gave about 178 errors saying identifiers were undefined, even
though they were declared right there. A stray `(*` inside a comment caused it.
CODESYS nests block comments, so it opened a second one and the `*)` after it
only closed the inner. Everything after that was treated as comment. The editor
still coloured the code normally, which is what made it hard to see.