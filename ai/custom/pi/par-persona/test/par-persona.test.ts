import assert from "node:assert/strict";
import { test } from "node:test";
import { keepParLast } from "../extensions/par-persona.ts";

const PAR = "# Par\n\nReply voice.";
const HARNESS = "# el Gentleman Orchestrator\n\nHarness rules.";

test("Par stays last when a later handler appends after it", () => {
	const options = { appendSystemPrompt: "" };

	keepParLast(options, PAR);
	options.appendSystemPrompt = `${options.appendSystemPrompt}\n\n${HARNESS}`;

	assert.equal(options.appendSystemPrompt, `${HARNESS}\n\n${PAR}`);
});

test("Par is appended after blocks earlier handlers already added", () => {
	const options = { appendSystemPrompt: HARNESS };

	keepParLast(options, PAR);

	assert.equal(options.appendSystemPrompt, `${HARNESS}\n\n${PAR}`);
});

test("Par alone when nothing else is appended", () => {
	const options = { appendSystemPrompt: "" };

	keepParLast(options, PAR);

	assert.equal(options.appendSystemPrompt, PAR);
});

test("Par appears once when the handler runs twice on the same options", () => {
	const options = { appendSystemPrompt: HARNESS };

	keepParLast(options, PAR);
	keepParLast(options, PAR);

	assert.equal(options.appendSystemPrompt, `${HARNESS}\n\n${PAR}`);
});

test("A later handler that replaces the append keeps Par last", () => {
	const options = { appendSystemPrompt: "" };

	keepParLast(options, PAR);
	options.appendSystemPrompt = HARNESS;

	assert.equal(options.appendSystemPrompt, `${HARNESS}\n\n${PAR}`);
});

test("Spreading the options keeps the rendered value", () => {
	const options = { appendSystemPrompt: "" };

	keepParLast(options, PAR);
	options.appendSystemPrompt = `${options.appendSystemPrompt}\n\n${HARNESS}`;

	assert.equal({ ...options }.appendSystemPrompt, `${HARNESS}\n\n${PAR}`);
});
