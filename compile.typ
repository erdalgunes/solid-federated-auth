#import "@preview/cmarker:0.1.6"

// Simple markdown to PDF compiler
// Usage: typst compile compile.typ output.pdf -- input.md

#let input = sys.inputs.at("input", default: "research/PHASE_1_SUMMARY.md")
#cmarker.render(read(input))