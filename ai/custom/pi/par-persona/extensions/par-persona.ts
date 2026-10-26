import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

// Keeps the Par reply voice as the last block of the appended system prompt,
// after gentle-pi's harness, so it outranks the persona and reply-shape rules
// that gentle-pi appends.
//
// Extension load order cannot guarantee that: it follows the `packages` list in
// ~/.pi/agent/settings.json, which Pi rebuilds as it installs, so whichever
// store path changed last ends up last. Instead, the handler turns
// appendSystemPrompt into an accessor on the per-run options object every
// before_agent_start handler shares: later handlers read and write it as usual,
// and every read renders their text followed by Par.
//
// The block goes into systemPromptOptions.appendSystemPrompt rather than a
// returned systemPrompt because pi-claude-bridge forwards only the structured
// options (gentle-shell#1485).

const PAR_PATH = fileURLToPath(new URL("../par.md", import.meta.url));

type AppendOptions = { appendSystemPrompt?: string };

export default function parPersona(pi: ExtensionAPI, env: NodeJS.ProcessEnv = process.env): void {
	// Par governs replies to the human; gentle-pi subagents report to the parent.
	if (env.GENTLE_PI_AGENTS_CHILD === "1") return;

	const par = readFileSync(PAR_PATH, "utf8").trim();

	pi.on("before_agent_start", async (event) => {
		const options = event.systemPromptOptions;
		if (!options || par === "") return;
		keepParLast(options, par);
	});
}

export function keepParLast(options: AppendOptions, par: string): void {
	let rest = withoutPar(options.appendSystemPrompt ?? "", par);
	Object.defineProperty(options, "appendSystemPrompt", {
		configurable: true,
		enumerable: true,
		get: () => (rest === "" ? par : `${rest}\n\n${par}`),
		set: (value: string | undefined) => {
			rest = withoutPar(value ?? "", par);
		},
	});
}

// Later handlers typically write `${current}\n\n${block}`, which carries the
// rendered Par along; dropping it here keeps it from appearing twice.
function withoutPar(text: string, par: string): string {
	return text
		.split(par)
		.map((part) => part.trim())
		.filter((part) => part !== "")
		.join("\n\n");
}
