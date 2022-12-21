/* High on Life Load Remover v1.0
 * by Jujstme & heny
 * 
 * Main signature scanning logic done by Jujstme
 *
 * Features:
 * - Pauses the timer during loading screens
 * - Automatically starts the timer on the beginning of intro
 * - Should support every current + future version of the game on PC, no matter which store
 * 
 * Note:
 * There are two types of loads in the game: actual loading screens & in-game loading zones. The load remover pauses the
 * timer only on loading screens as in-game loading zones allow the player to move around, making fair pausing impossible.
 */

state("Oregon-Win64-Shipping") {} // Steam
state("Oregon-WinGDK-Shipping") {} // Xbox App/Game Pass

init
{
  vars.watchers = new MemoryWatcherList();
    
  // ==========================================================
  // Helper functions
  // ==========================================================
  
  Action<IntPtr> CheckForNullPointer = (ptr) => { 
    if (ptr == IntPtr.Zero) {
      throw new NullReferenceException();
    }
  };
  
  Action SetupMemoryWatchers = () => {  
    var sigScanner = new SignatureScanner(game, modules.First().BaseAddress, modules.First().ModuleMemorySize);
    var ptr = IntPtr.Zero;    

    ptr = sigScanner.Scan(new SigScanTarget(-4, "89 43 60 8B 05") { 
      OnFound = (process, scanner, addr) => addr + 0x4 + process.ReadValue<int>(addr)
    });
    CheckForNullPointer(ptr);    
    vars.watchers.Add(new MemoryWatcher<bool>(ptr) { Name = "loading" });

    ptr = sigScanner.Scan(new SigScanTarget(2, "01 05 ???????? 8B 05 ???????? 85 C0") { 
      OnFound = (process, scanner, addr) => addr + 0x4 + process.ReadValue<int>(addr)
    });    
    CheckForNullPointer(ptr);  
    vars.watchers.Add(new MemoryWatcher<bool>(ptr) { Name = "loadingPortal" });
  };

  // ==========================================================
  // Game initialization
  // ==========================================================
  
  SetupMemoryWatchers();
}


startup
{
  // ==========================================================
  // Helper functions
  // ==========================================================

  Action ShowGameTimeWarningIfApplicable = () => {
    if (timer.CurrentTimingMethod == TimingMethod.RealTime) {
      var dialogResult =
        MessageBox.Show(
          timer.Form,
          "This game uses \"RTA without loads\" (Game Time in LiveSplit) as the main timing method.\n"
          + "LiveSplit currently is set to show \"Real Time\". Would you like to change the timing method to \"Game Time\"?",
          "High on Life Autosplitter - Timing Method",
          MessageBoxButtons.YesNo,
          MessageBoxIcon.Question
        );

      if (dialogResult == DialogResult.Yes) {
        timer.CurrentTimingMethod = TimingMethod.GameTime;
      }
    }
  };
  
  // ==========================================================
  // Script startup
  // ==========================================================
  
  ShowGameTimeWarningIfApplicable();
}

update
{
  vars.watchers.UpdateAll(game);
}

onStart
{
  timer.IsGameTimePaused = true; // Make sure the timer always starts at 0.00
}

start
{
  return vars.watchers["loading"].Old && !vars.watchers["loading"].Current
    && !vars.watchers["loadingPortal"].Current && !vars.watchers["loadingPortal"].Old;
}

exit
{
  timer.IsGameTimePaused = true;  
}

isLoading
{    
  return vars.watchers["loading"].Current || vars.watchers["loadingPortal"].Current;
}
