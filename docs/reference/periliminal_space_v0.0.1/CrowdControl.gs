function fillCrowdControlFile() {
  var root = DriveApp.getFoldersByName("Periliminal").next();
  var coreFolder = root.getFoldersByName("core").next();

  var ccFile;
  var files = coreFolder.getFilesByName("crowd_control.py");
  if (files.hasNext()) {
    ccFile = files.next();
  } else {
    ccFile = coreFolder.createFile("crowd_control.py", "");
  }

  var ccContent = `
# =====================================
# PERILIMINAL - CROWD CONTROL SYSTEM
# =====================================

# Core Design:
# - Control scales with the Control stat
# - CC never fully locks a player indefinitely
# - Diminishing returns apply
# - Heavy Frames resist CC better
# - Rigs and Races modify CC behavior

# -------------------------------------
# CC TYPES
# -------------------------------------

CC_TYPES = {
    "stun": {
        "base_duration": 2.0,
        "break_on_damage": False
    },
    "root": {
        "base_duration": 3.0,
        "break_on_damage": False
    },
    "silence": {
        "base_duration": 2.5,
        "break_on_damage": False
    },
    "knockdown": {
        "base_duration": 1.5,
        "break_on_damage": False
    },
    "fear": {
        "base_duration": 2.0,
        "break_on_damage": True
    },
    "slow": {
        "base_duration": 4.0,
        "break_on_damage": False
    }
}

# -------------------------------------
# DIMINISHING RETURNS SYSTEM
# -------------------------------------

DIMINISHING_WINDOW = 15  # seconds
DIMINISHING_FACTOR = 0.6  # 40% reduction per repeated CC

def apply_diminishing_returns(previous_applications):
    """
    previous_applications: how many times target has been CC'd recently
    """
    if previous_applications == 0:
        return 1.0
    return DIMINISHING_FACTOR ** previous_applications


# -------------------------------------
# CC RESISTANCE CALCULATION
# -------------------------------------

def calculate_cc_duration(cc_type, attacker_control, defender_control_resist, previous_cc):
    """
    cc_type: string key from CC_TYPES
    attacker_control: attacker's control stat
    defender_control_resist: defender resistance stat
    previous_cc: number of CC applications within window
    """

    base = CC_TYPES[cc_type]["base_duration"]

    # Control scaling
    control_scaling = 1 + (attacker_control / 100)

    # Resistance scaling
    resistance_scaling = 1 - (defender_control_resist / 100)

    # Diminishing returns
    diminishing = apply_diminishing_returns(previous_cc)

    duration = base * control_scaling * resistance_scaling * diminishing

    # Hard minimum so CC never disappears entirely
    if duration < 0.5:
        duration = 0.5

    return duration


# -------------------------------------
# BREAK FREE SYSTEM
# -------------------------------------

BREAK_FREE_COST = 25  # stamina or energy

def can_break_free(resource_pool):
    return resource_pool >= BREAK_FREE_COST


# -------------------------------------
# IMMUNITY WINDOW
# -------------------------------------

IMMUNITY_AFTER_STUN = 3  # seconds

# After hard CC ends, player gains brief resistance window


# -------------------------------------
# HEAVY FRAME BONUS
# -------------------------------------

HEAVY_FRAME_CC_REDUCTION = 0.15  # 15% reduction to incoming CC duration


# -------------------------------------
# SUPPRESSION STATE
# -------------------------------------

# Triggered after Heavy Ultimates
SUPPRESSION_DURATION_RANGE = (30, 60)

# During suppression:
# - CC durations reduced by 50%
# - Movement reduced by 25%
# - Ultimate locked


`;
  ccFile.setContent(ccContent);
  Logger.log("Crowd Control system created/updated.");
}