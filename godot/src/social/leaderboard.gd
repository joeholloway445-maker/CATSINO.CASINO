class_name Leaderboard
extends Node

signal loaded(entries: Array[Dictionary])

func fetch(board_id: String = "global_wins", limit: int = 20) -> void:
	NetworkManager.call_rpc("get_leaderboard", {board_id=board_id, limit=limit},
		func(result: Dictionary):
			var records: Array[Dictionary] = []
			for rec in result.get("records", []):
				records.append({
					rank=rec.get("rank", 0),
					username=rec.get("username", "Unknown"),
					score=rec.get("score", 0),
					subscore=rec.get("subscore", 0),
				})
			loaded.emit(records)
	)

func submit_score(board_id: String, score: int) -> void:
	NetworkManager.call_rpc("submit_score", {board_id=board_id, score=score}, func(_r): pass)
