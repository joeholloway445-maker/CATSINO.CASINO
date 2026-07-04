extends Node
## Posts UGC mod-review tickets to a Discord webhook. This is the lightest
## real integration possible without a hosted bot/token: a Discord webhook
## URL (created in the target channel's Integrations settings) accepts
## plain POSTs, no bot process required. Set webhook_url before calling
## (e.g. via an environment-specific autoload override or .env-loaded
## config) — left blank by default since it's a per-server secret that
## doesn't belong committed to the repo.

@export var webhook_url: String = ""

## Posts a new ticket message and returns the submission's discord_ticket_url
## (the channel link), or "" if posting failed/was skipped (no webhook configured).
func post_ticket(submission: UgcSubmission) -> String:
	if webhook_url.is_empty():
		push_warning("DiscordTicketClient: no webhook_url configured, skipping post.")
		return ""
	var content := "**New UGC submission for review**\nID: `%s`\nCreator: `%s`\nSource mode: `%s`%s" % [
		submission.id,
		submission.creator_player_id,
		submission.source_mode_id,
		"" if submission.timeline_mode.is_empty() else "\nTimeline: `%s`" % submission.timeline_mode,
	]
	var http := HTTPRequest.new()
	add_child(http)
	var headers := PackedStringArray(["Content-Type: application/json"])
	var body := JSON.stringify({"content": content})
	var err := http.request(webhook_url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		http.queue_free()
		push_warning("DiscordTicketClient: failed to start request (%d)" % err)
		return ""
	var response: Array = await http.request_completed
	http.queue_free()
	var result: int = response[0]
	var status_code: int = response[1]
	if result != HTTPRequest.RESULT_SUCCESS or status_code < 200 or status_code >= 300:
		push_warning("DiscordTicketClient: webhook post failed (result=%d status=%d)" % [result, status_code])
		return ""
	return webhook_url
