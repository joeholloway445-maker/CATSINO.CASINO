class_name UgcSubmission
extends Resource
## Tracks a single piece of user-generated content through the review
## pipeline shared by every UGC source in the game (Creator-mode timelines,
## Undercroft sandbox exports, marketplace listings): a Discord mod ticket
## first, then dev (currently just the two of us) sign-off before anything
## is implemented into canon.

enum Status { PENDING, MOD_REVIEW, MOD_APPROVED, MOD_REJECTED, DEV_IMPLEMENTED }

@export var id: String = ""
@export var creator_player_id: String = ""
@export var source_mode_id: String = "" # e.g. "creator_replay", "creator_original", "subliminal_sandbox"
@export var timeline_mode: String = "" # "replay" or "original", only meaningful for creator modes
@export var discord_ticket_url: String = ""
@export var status: Status = Status.PENDING
@export var mod_notes: String = ""

func advance_to_mod_review(ticket_url: String) -> void:
	discord_ticket_url = ticket_url
	status = Status.MOD_REVIEW

## Posts this submission to the configured Discord webhook (DiscordTicketClient)
## and advances to MOD_REVIEW with the resulting ticket link. If no webhook is
## configured, still advances to MOD_REVIEW with an empty ticket_url so the
## submission isn't stuck — mods can be notified manually until a webhook is set.
func submit_ticket() -> void:
	var ticket_url: String = await DiscordTicketClient.post_ticket(self)
	advance_to_mod_review(ticket_url)

func mod_decide(approved: bool, notes: String = "") -> void:
	status = Status.MOD_APPROVED if approved else Status.MOD_REJECTED
	mod_notes = notes

func mark_implemented() -> void:
	if status == Status.MOD_APPROVED:
		status = Status.DEV_IMPLEMENTED
