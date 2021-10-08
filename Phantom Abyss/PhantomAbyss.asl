/* Phantom Abyss Load Remover & Autosplitter v1.3
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

// Steam, Current Version (2021/10/01, Update 18)
state("PhantomAbyss-Win64-Shipping", "Build_7429581")
{  
  // ULoadingScreenWidgetBP_C.HintText + Offset 1D8
  int loading : "PhantomAbyss-Win64-Shipping.exe", 0x46C4378, 0xDE8, 0x4C0, 0xDB8, 0x1D8;

  // UWIBYHUD_BP_C.loadingPanel.Visibility
  bool loadingPanelInvisible : "PhantomAbyss-Win64-Shipping.exe", 0x46B1980, 0x30, 0x260, 0xC70, 0x410, 0xC3;

  // AGod_Hub_Altar_BP_C (0_HUB.HUB.PersistentLevel.God_Hub_Alter_BP_3) [Active God Hub Altar: 0x97E0]
  ushort godHubAltar : "PhantomAbyss-Win64-Shipping.exe", 0x46C7A00, 0x130, 0x420, 0x670, 0x0;

  // MainMenuGameMode_C [Active Main Menu: 0xD858]
  ushort mainMenuGameMode : "PhantomAbyss-Win64-Shipping.exe", 0x40C9A00, 0x0, 0x128, 0x0;

  // AWIBYExplorerCharacter.targetedInteraction
  long targetedInteraction : "PhantomAbyss-Win64-Shipping.exe", 0x46B1980, 0x30, 0x250, 0x890;

  // AWIBYExplorerCharacter.targetedInteraction + Offset 20C [Relic: 0x0E]
  ushort targetedInteractionType : "PhantomAbyss-Win64-Shipping.exe", 0x46B1980, 0x30, 0x250, 0x890, 0x20C;

  // AWIBYExplorerCharacter.targetedInteraction + Offset 2A9 [Relic collected]
  bool relicCanBePickedUp : "PhantomAbyss-Win64-Shipping.exe", 0x46B1980, 0x30, 0x250, 0x890, 0x2A9;
  
  // UUserSave.m_numFloorsCompleted
  int numFloorsCompleted : "PhantomAbyss-Win64-Shipping.exe", 0x46C34C8, 0x8, 0x360, 0x48;

  // DungeonWideSwitchTracking_C + Offset 178
  bool brazierLitUp : "PhantomAbyss-Win64-Shipping.exe", 0x46B1980, 0x30, 0x250, 0x850, 0x2F0, 0x60, 0x20, 0x180;
  
  // AHUBWhipSelectPedestalBP_C.whipID [Tutorial Pedestal: 0x11322]
  long whipSelectPedestalWhipID : "PhantomAbyss-Win64-Shipping.exe", 0x46C7A00, 0x130, 0x420, 0x488, 0x39C;

  // UCapsuleComponent + Offset 2B0 (0_Tutorial_StartRoom_3.Tutorial_StartRoom_3.PersistentLevel.HUBWhipSelectPedestalBP_3.InteractCapsule)
  bool tutorialWhipInteractableWith : "PhantomAbyss-Win64-Shipping.exe", 0x46C7A00, 0x130, 0x420, 0x488, 0x290, 0x2B0;
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
    vars.wasInMainMenu = false;
    vars.enteredTemple = false;
    vars.enteredTutorial = false;
    vars.leftTemple = false;
    vars.backupAddr = 0;
  });

  vars.AddSettings = (Action) (() => {
    settings.Add("splits", true, "Splits");
    settings.Add("templeSplits", true, "Temple", "splits");
    settings.Add("splitOnFloorChange", true, "Floor Change", "templeSplits");
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
  
  refreshRate = 90;
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
        vars.DebugInLayout("loading", current.loading.ToString());
        vars.DebugInLayout("loadingPanelInvisible", current.loadingPanelInvisible.ToString());
      }
    
      if (settings["showAreaDebugInfo"]) {
        vars.DebugInLayout("godHubAltar", current.godHubAltar.ToString("X"));
        vars.DebugInLayout("wasInMainMenu", vars.wasInMainMenu.ToString());
        vars.DebugInLayout("enteredTemple", vars.enteredTemple.ToString());
        vars.DebugInLayout("enteredTutorial", vars.enteredTutorial.ToString());
        vars.DebugInLayout("leftTemple", vars.leftTemple.ToString());
        vars.DebugInLayout("whipSelectPedestalWhipID", current.whipSelectPedestalWhipID.ToString("X"));
      }
    
      if (settings["showSplittingDebugInfo"]) {
        vars.DebugInLayout("targetedInteraction", current.targetedInteraction.ToString("X"));
        vars.DebugInLayout("targetedInteractionType", current.targetedInteractionType.ToString("X"));
        vars.DebugInLayout("relicCanBePickedUp", current.relicCanBePickedUp.ToString());
        vars.DebugInLayout("numFloorsCompleted", current.numFloorsCompleted.ToString());
        vars.DebugInLayout("brazierLitUp", current.brazierLitUp.ToString());
        vars.DebugInLayout("tutorialWhipInteractableWith", current.tutorialWhipInteractableWith.ToString());
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
      case "B81DA415D8B4A57CFF5A3339DBBD663D":
        version = "Build_7458269";
        
        break;
      default:
      
        // Using the latest known game version's state descriptor if the detected version is unknown
        version = "Build_7458269";

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
  vars.timerModel.Reset();
}

start
{
  bool startTimer = false;
  
  vars.enteredTutorial = (current.whipSelectPedestalWhipID == 0x11322);
  if ((vars.enteredTemple || vars.enteredTutorial) && (old.loading != 0 && current.loading == 0)) {
    vars.wasInMainMenu = false;
    startTimer = true;
  }
  
  return startTimer;
}

reset
{
  bool resetTimer = false;
  
  if (vars.wasInMainMenu || (vars.leftTemple && (old.loading != 0 && current.loading == 0))) {
    resetTimer = true;
  }
    
  return resetTimer;
}

update {  
  
  // Check if the main menu is active
  if (current.mainMenuGameMode == 0xD858) { 
    vars.wasInMainMenu = true;
    vars.enteredTemple = false;
  }
  
  // Transitioning from hub to temple or main menu
  if (old.godHubAltar == 0x97E0 && current.godHubAltar == 0) {
    vars.leftTemple = false;
    vars.enteredTemple = true;
    
    if (timer.CurrentPhase == TimerPhase.Running || timer.CurrentPhase == TimerPhase.Paused || timer.CurrentPhase == TimerPhase.Ended) {    
      timer.OnReset -= vars.OnReset;
      vars.timerModel.Reset();
      vars.relicPickedUp = false;
      timer.OnReset += vars.OnReset;
    }
  }

  // Transitioning from temple or main menu to hub
  if (old.godHubAltar == 0 && current.godHubAltar == 0x97E0) {
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
  return current.loading != 0 || !current.loadingPanelInvisible;
}

split
{

  // Split for the pickup of a relic or sandbag
  if (current.targetedInteractionType == 0x0E && old.relicCanBePickedUp && !current.relicCanBePickedUp) {
    if (current.loading == 0 && current.loadingPanelInvisible) {
      return true;
    }
  }
  
  // Split for the pickup of the tutorial whip
  if (settings["splitOnTutorialWhipPickup"]) {    
    if (old.tutorialWhipInteractableWith && !current.tutorialWhipInteractableWith) {      
      vars.enteredTutorial = (current.whipSelectPedestalWhipID == 0x11322);
      if (vars.enteredTutorial) {
        return true;
      }
    }
  }
    
  // Split for the kindling of braziers
  if (settings["splitOnBrazierKindling"] && vars.enteredTemple) {    
    if (!old.brazierLitUp && current.brazierLitUp) {
      if (current.loading == 0 && current.loadingPanelInvisible) {
        return true;
      }
    }
  }

  // Split upon changing the temple's floor
  if (settings["splitOnFloorChange"]) {    
    if (old.numFloorsCompleted < current.numFloorsCompleted) {
      return true;
    }
  }
}
