import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Appends the Par reply voice as the last block of the system prompt, after
// gentle-pi's harness, so it outranks the persona and reply-shape rules that
// gentle-pi appends. This only works when this package loads after
// gentle-shell: handlers run in extension load order.
//
// The block goes into systemPromptOptions.appendSystemPrompt rather than a
// returned systemPrompt because pi-claude-bridge forwards only the structured
// options (gentle-shell#1485).

const PAR_PATH = fileURLToPath(new URL("../par.md", import.meta.url));
const GENTLE_MARKER = "# el Gentleman Orchestrator";

export default function parPersona(pi: ExtensionAPI, env: NodeJS.ProcessEnv = process.env): void {
	// Par governs replies to the human; gentle-pi subagents report to the parent.
	if (env.GENTLE_PI_AGENTS_CHILD === "1") return;

	const par = readFileSync(PAR_PATH, "utf8").trim();
	let orderWarned = false;

	pi.on("before_agent_start", async (event, ctx) => {
		const options = event.systemPromptOptions;
		if (!options || par === "") return;

		const current = options.appendSystemPrompt ?? "";
		if (!orderWarned && !current.includes(GENTLE_MARKER)) {
			orderWarned = true;
			ctx.ui.notify("par-persona ran before gentle-pi; Par is not the last prompt block", "warning");
		}
		if (current.endsWith(par)) return;
		options.appendSystemPrompt = current === "" ? par : `${current}\n\n${par}`;
	});
}
