# Where every skill in ~/.claude/skills comes from.
#
# One entry per upstream. `clone` is the checkout path relative to ~/Developer,
# `rev` is the commit ./skills.nix pins it to at activation, and `skills` maps
# each installed skill name to its directory inside the checkout.
#
# A `rev` of null means "clone it once, then leave it alone": that is the
# private repo, which is edited in place.
#
# Adding an upstream skill is adding its name to a list here. Anything that
# needs local edits lives in qnm/skills instead, so these checkouts stay clean
# and a `rev` bump is a plain fast-forward.
{ lib }:
let
  under = dir: names: lib.genAttrs names (name: if dir == "" then name else "${dir}/${name}");
in
{
  mattpocock = {
    url = "https://github.com/mattpocock/skills";
    rev = "74ca5fe077456a0b3b2f5310cf9430999fd0b5fd";
    clone = "mattpocock/skills";
    skills =
      under "skills/engineering" [
        "ask-matt"
        "code-review"
        "diagnosing-bugs"
        "domain-modeling"
        "grill-with-docs"
        "implement"
        "improve-codebase-architecture"
        "prototype"
        "resolving-merge-conflicts"
        "setup-matt-pocock-skills"
        "to-spec"
        "to-tickets"
        "triage"
        "wayfinder"
        "wizard"
      ]
      // under "skills/productivity" [
        "grill-me"
        "grilling"
        "handoff"
        "teach"
        "to-questionnaire"
        "wait-what"
        "writing-for-agents"
      ];
  };

  pstack = {
    url = "https://github.com/michael-denyer/pstack-claude";
    rev = "430a4f5d1fdcba0750ffa21e441ced5114f7d8ce";
    clone = "michael-denyer/pstack-claude";
    # pstack's own `tdd` and `teach` collide with mattpocock's; the renamed
    # copies live in qnm/skills.
    skills = under "plugins/pstack/skills" [
      "architect"
      "arena"
      "automate-me"
      "babysit"
      "blast-radius"
      "bro"
      "create-verification-skill"
      "deslop"
      "figure-it-out"
      "fix-ci"
      "fix-merge-conflicts"
      "get-pr-comments"
      "how"
      "interrogate"
      "maintain-verification-skill"
      "make-pr-easy-to-review"
      "no-comments"
      "poteto-mode"
      "principle-attack-the-premise"
      "principle-boundary-discipline"
      "principle-build-the-lever"
      "principle-encode-lessons-in-structure"
      "principle-exhaust-the-design-space"
      "principle-experience-first"
      "principle-fix-root-causes"
      "principle-foundational-thinking"
      "principle-guard-the-context-window"
      "principle-laziness-protocol"
      "principle-make-operations-idempotent"
      "principle-migrate-callers-then-delete-legacy-apis"
      "principle-minimize-reader-load"
      "principle-model-the-domain"
      "principle-never-block-on-the-human"
      "principle-outcome-oriented-execution"
      "principle-prove-it-works"
      "principle-redesign-from-first-principles"
      "principle-separate-before-serializing-shared-state"
      "principle-sequence-verifiable-units"
      "principle-subtract-before-you-add"
      "principle-test-behavior-not-implementation"
      "principle-type-system-discipline"
      "recall"
      "reflect"
      "setup-pstack"
      "show-me-your-work"
      "swarm"
      "technical-writing"
      "thermo-nuclear-code-quality-review"
      "typescript-best-practices"
      "unslop"
      "what-did-i-get-done"
      "why"
    ];
  };

  quint = {
    url = "https://github.com/quint-co/quint-llm-kit";
    rev = "cc75369f741af7d490936f82002c2d28e3b3d78d";
    clone = "quint-co/quint-llm-kit";
    # The kit's `agentic/` slash commands are deliberately left out: they assume
    # its Docker image and container-path MCP servers.
    skills = under "quint-llm-kit-plugin/skills" [
      "quint-execute-spec"
      "quint-lang"
      "quint-modeling"
    ];
  };

  qnm = {
    url = "https://github.com/qnm/skills";
    rev = null;
    clone = "qnm/skills";
    # Private: hand-written skills, plus forks that carry local edits or a
    # rename. See that repo's README for which is which.
    skills = under "" [
      "bot-review-loop"
      "codebase-design"
      "external-ticket-writing"
      "pstack-tdd"
      "pstack-teach"
      "research"
      "robin-voice"
      "tdd"
    ];
  };
}
