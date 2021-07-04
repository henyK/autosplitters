/* Phantom Abyss Load Remover & Autosplitter v1.0
 * by heny (Thanks to Micrologist for helping with a few things)
 * Tested only with the current version of the game's Steam release
 *
 * Features:
 * - Supports both tutorial and temple runs (all tiers)
 * - Pauses the timer during loading screens
 * - Automatically splits upon changing the temple's floor
 * - Automatically splits upon picking up the tutorial whip
 * - Automatically splits upon lighting up braziers
 * - Automatically splits upon collecting the relic
 */

// Steam, Current Version (2021/07/02, Update 10)
state("PhantomAbyss-Win64-Shipping", "Build_6970928")
{
  // ULoadingScreenWidget.ActiveSequencePlayers [Byte changing twice to 0x4]
  int loadingIndicator : "PhantomAbyss-Win64-Shipping.exe", 0x46B5408, 0x8, 0x348, 0x184;

  // AGod_Hub_Altar_BP_C (0_HUB.HUB.PersistentLevel.God_Hub_Alter_BP_3) [Active God Hub Altar: 0xCAA0]
  ushort godHubAltar : "PhantomAbyss-Win64-Shipping.exe", 0x46B9940, 0x130, 0x420, 0x670, 0x0;

  // MainMenuGameMode_C [Active Main Menu: 0x0B78]
  ushort mainMenuGameMode : "PhantomAbyss-Win64-Shipping.exe", 0x4177DA0, 0x0, 0x128, 0x0;

  // RelicTutorial_C.CanActivate
  bool tutorialRelicCollectable : "PhantomAbyss-Win64-Shipping.exe", 0x046F2600, 0x28, 0x48, 0x490, 0x2B1;
  
  // Relic_Master_C.CanActivate
  bool templeRelicCollectable : "PhantomAbyss-Win64-Shipping.exe", 0x046B9940, 0x130, 0x428, 0x20, 0x98, 0x50, 0x2B1;

  // UUSerSave.m_numFloorsCompleted
  int numFloorsCompleted : "PhantomAbyss-Win64-Shipping.exe", 0x46B5408, 0x8, 0x2C8, 0x48;

  // AHUBWhipSelectPedestalBP_C.whipID [Tutorial Pedestal ID: 0x11322]
  long whipSelectPedestalID : "PhantomAbyss-Win64-Shipping.exe", 0x4512080, 0xB0, 0x400, 0x730, 0x800, 0xE8, 0x488, 0x39C;
  
  // UCapsuleComponent + Offset 2B0 (0_Tutorial_StartRoom_3.Tutorial_StartRoom_3.PersistentLevel.HUBWhipSelectPedestalBP_3.InteractCapsule)
  short tutorialWhipInteractableWith : "PhantomAbyss-Win64-Shipping.exe", 0x4575E68, 0x118, 0x488, 0x290, 0x2B0;
  
  // DungeonWideSwitchTracking_C + Offset 180
  bool brazierLitUp : "PhantomAbyss-Win64-Shipping.exe", 0x46A38C0, 0x30, 0x260, 0xE40, 0x340, 0x180;
}

startup
{
  // ==========================================================
  // Helper functions
  // ==========================================================

  // Creates a debug text component at the bottom of the current layout
  vars.DebugInLayout = (Action<string, string>)((id, text) => {
    var textSettings = timer.Layout.Components.Where(x => x.GetType().Name == "TextComponent").Select(x => x.GetType().GetProperty("Settings").GetValue(x, null));
    string textSettingID = "dbg_" + id;
    var textSetting = textSettings.FirstOrDefault(x => (x.GetType().GetProperty("Text1").GetValue(x, null) as string) == textSettingID);
        
    if (textSetting == null) {
      var textComponentAssembly = Assembly.LoadFrom("Components\\LiveSplit.Text.dll");
      var textComponent = Activator.CreateInstance(textComponentAssembly.GetType("LiveSplit.UI.Components.TextComponent"), timer);
      
      timer.Layout.LayoutComponents.Add(new LiveSplit.UI.Components.LayoutComponent("LiveSplit.Text.dll", textComponent as LiveSplit.UI.Components.IComponent));

      textSetting = textComponent.GetType().GetProperty("Settings", BindingFlags.Instance | BindingFlags.Public).GetValue(textComponent, null);
      textSetting.GetType().GetProperty("Text1").SetValue(textSetting, textSettingID);
    }

    if (textSetting != null) {
      textSetting.GetType().GetProperty("Text2").SetValue(textSetting, text);
    }
  });
  
  vars.ResetVariables = (Action) (() => {
    vars.loadingCounter = 0;
    vars.finishedLoading = false;
    vars.isLoading = false;
    vars.wasInMainMenu = false;
    vars.enteredTutorial = false;
    vars.enteredTemple = false;
    vars.leftTemple = false;
    vars.relicPickedUp = false;
  });

  vars.AddSettings = (Action) (() => {
    settings.Add("splits", true, "Splits");
    settings.Add("templeSplits", true, "Temple", "splits");
    settings.Add("splitOnFloorChange", true, "Temple Floor Change", "templeSplits");
    settings.Add("splitOnBrazierKindling", false, "Braziers", "templeSplits");
    settings.Add("tutorialSplits", true, "Tutorial", "splits");
    settings.Add("splitOnTutorialWhipPickup", false, "Tutorial Whip", "tutorialSplits");
    settings.Add("debugOptions", false, "Debug Options (Only enable when asked for)");
    settings.Add("showLoadingDebugInfo", false, "Show loading debug info", "debugOptions");
    settings.Add("showAreaDebugInfo", false, "Show area debug info", "debugOptions");
    settings.Add("showSplittingDebugInfo", false, "Show splitting debug info", "debugOptions");
  });

  // ==========================================================
  // Event handlers
  // ==========================================================

  vars.OnReset = (LiveSplit.Model.Input.EventHandlerT<TimerPhase>)((s, e) => {
    vars.ResetVariables();
  });

  // ==========================================================
  // Script startup
  // ==========================================================

  vars.AddSettings();

  timer.OnReset += vars.OnReset;

  vars.timerModel = new TimerModel { CurrentState = timer };
}

shutdown
{
  timer.OnReset -= vars.OnReset;
}

init
{
  // ==========================================================
  // Helper functions
  // ==========================================================

  vars.ShowDebugInfo = (Action) (() => {
    if (settings["debugOptions"]) {
      if (settings["showLoadingDebugInfo"]) {
        vars.DebugInLayout("isLoading", vars.isLoading.ToString());
        vars.DebugInLayout("finishedLoading", vars.finishedLoading.ToString());
        vars.DebugInLayout("loadingCounter", vars.loadingCounter.ToString());
      }
    
      if (settings["showAreaDebugInfo"]) {
        vars.DebugInLayout("wasInMainMenu", vars.wasInMainMenu.ToString());
        vars.DebugInLayout("whipSelectPedestalID", current.whipSelectPedestalID.ToString("X"));
        vars.DebugInLayout("godHubAltar", current.godHubAltar.ToString("X"));
        vars.DebugInLayout("enteredTutorial", vars.enteredTutorial.ToString());
        vars.DebugInLayout("enteredTemple", vars.enteredTemple.ToString());
        vars.DebugInLayout("leftTemple", vars.leftTemple.ToString());
      }
    
      if (settings["showSplittingDebugInfo"]) {
        vars.DebugInLayout("tutorialWhipInteractableWith", current.tutorialWhipInteractableWith.ToString());
        vars.DebugInLayout("numFloorsCompleted", current.numFloorsCompleted.ToString()); 
        vars.DebugInLayout("brazierLitUp", current.brazierLitUp.ToString());
        vars.DebugInLayout("tutorialRelicCollectable", current.tutorialRelicCollectable.ToString());
        vars.DebugInLayout("templeRelicCollectable", current.templeRelicCollectable.ToString());
        vars.DebugInLayout("relicPickedUp", vars.relicPickedUp.ToString()); 
      }
    }
  });

  vars.DetermineGameVersion = (Action) (() => {
    string md5Hash;

    using (var md5 = System.Security.Cryptography.MD5.Create()) {
      using (var executable = File.Open(modules.First().FileName, FileMode.Open, FileAccess.Read, FileShare.ReadWrite)) {
        md5Hash = md5.ComputeHash(executable).Select(hashBytes => hashBytes.ToString("X2")).Aggregate((a, b) => a + b);
      }
    }

    version = "";
    switch (md5Hash) {
      case "BA523CF86CE25769A2BB10F58F3E521A":
        version = "Build_6970928";
        break;
      default:
        version = "Build_6970928";

        MessageBox.Show(
          timer.Form,
          "This game version is not explicitly supported as there was a recent update. Thus the autosplitter might not work properly at the moment. "
          + "It will be fixed as soon as possible. Until then you are free to either wait before doing additional runs or just submit your runs using "
          + "\"Real Time\" so that they can be retimed by the moderation team.",
          "Phantom Abyss Autosplitter - Unsupported Game Version",
          MessageBoxButtons.OK,
          MessageBoxIcon.Error
        );

        break;
    }
  });

  vars.ShowGameTimeWarningIfApplicable = (Action) (() => {
    if (timer.CurrentTimingMethod == TimingMethod.RealTime) {
      var dialogResult =
        MessageBox.Show(
          timer.Form,
          "This game uses \"RTA without loads\" (Game Time in LiveSplit) as the main timing method.\n"
          + "LiveSplit currently is set to show \"Real Time\". Would you like to change the timing method to \"Game Time\"?",
          "Phantom Abyss Autosplitter - Timing Method",
          MessageBoxButtons.YesNo,
          MessageBoxIcon.Question
        );

      if (dialogResult == DialogResult.Yes) {
        timer.CurrentTimingMethod = TimingMethod.GameTime;
      }
    }
  });

  // ==========================================================
  // Game initialization
  // ==========================================================

  vars.DetermineGameVersion();
  vars.ShowGameTimeWarningIfApplicable();
  vars.ResetVariables();
}

exit
{
  vars.timerModel.Reset(true);
}

start
{
  vars.enteredTutorial = (current.whipSelectPedestalID == 0x11322);

  bool startTimer = false;
  if ((vars.enteredTemple || vars.enteredTutorial) && vars.finishedLoading) {
    vars.wasInMainMenu = false;
    startTimer = true;
  }

  return startTimer;
}

reset
{
  return vars.wasInMainMenu || (vars.leftTemple && vars.finishedLoading);    
}

update {

  // Check if the main menu is active
  if (current.mainMenuGameMode == 0x0B78) { 
    vars.wasInMainMenu = true;
    vars.enteredTemple = false;
  }
    
  // Determine if the game is done loading. Since the respective variable changes its value multiple times, we need to count the increments here.
  vars.finishedLoading = false;

  if (old.loadingIndicator < current.loadingIndicator) {
    vars.loadingCounter++;
  }

  if (vars.loadingCounter == 2) {
    if (old.loadingIndicator > current.loadingIndicator) {
      vars.finishedLoading = true;
      vars.loadingCounter = 0;
    }
  }

  vars.isLoading = vars.loadingCounter > 0;
	
  // Transitioning from hub to temple or main menu
  if (old.godHubAltar == 0xCAA0 && current.godHubAltar == 0) {
    vars.leftTemple = false;
    vars.enteredTemple = true;

    if (timer.CurrentPhase == TimerPhase.Running || timer.CurrentPhase == TimerPhase.Paused || timer.CurrentPhase == TimerPhase.Ended) {    
      timer.OnReset -= vars.OnReset;
      vars.timerModel.Reset(true);
      vars.relicPickedUp = false;
      timer.OnReset += vars.OnReset;
    }
  }

  // Transitioning from temple or main menu to hub
  if (old.godHubAltar == 0 && current.godHubAltar == 0xCAA0) {
    if (vars.wasInMainMenu) {
      vars.wasInMainMenu = false;
    } else {      
      vars.enteredTemple = false;
      vars.leftTemple = true;
    }
  }
    
  vars.ShowDebugInfo();
}

isLoading
{
  return vars.isLoading;
}

split
{
  // Split for the pickup of the tutorial relic
  if (vars.enteredTutorial && old.tutorialRelicCollectable && !current.tutorialRelicCollectable) {
    return true;
  }
  
  // Split for the pickup of the relic in a temple
  if (old.templeRelicCollectable && !current.templeRelicCollectable) {
    return true;
  }

  // Split for the pickup of the tutorial whip
  if (settings["splitOnTutorialWhipPickup"] && vars.enteredTutorial) {
    if (old.tutorialWhipInteractableWith == 0x1 && current.tutorialWhipInteractableWith == 0) {
      return true;
    }
  }
    
  // Split for the kindling of braziers
  if (settings["splitOnBrazierKindling"] && vars.enteredTemple) {    
    if (!old.brazierLitUp && current.brazierLitUp && !vars.isLoading) {
      return true;
    }
  }

  // Split upon changing the temple's floor
  if (settings["splitOnFloorChange"] && !vars.relicPickedUp) {    
    if (old.numFloorsCompleted < current.numFloorsCompleted) {
      return true;
    }
  }
}
