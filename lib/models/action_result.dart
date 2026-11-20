/// Outcome of a player action, with an optional message to show.
class ActionResult {
  const ActionResult.ok([this.message]) : ok = true;
  const ActionResult.fail(String this.message) : ok = false;

  final bool ok;
  final String? message;
}
