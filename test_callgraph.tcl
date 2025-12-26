#!/usr/bin/env tclsh
# Test script for call graph functionality

# Define test procedures
proc leaf_proc {} {
    after 10
    return "leaf"
}

proc middle_proc_a {} {
    leaf_proc
    leaf_proc
    return "middle_a"
}

proc middle_proc_b {} {
    leaf_proc
    return "middle_b"
}

proc top_proc {} {
    middle_proc_a
    middle_proc_b
    leaf_proc
    return "top"
}

proc main {} {
    top_proc
    top_proc
    middle_proc_a
}

# Load profiler
source tcl_profiler_complete.tcl

# Test 1: Without call graph
puts "\n=========================================="
puts "Test 1: Normal profiling (no call graph)"
puts "=========================================="
prof_init
prof_instrument_all
main
prof_summary
puts "\nTrying to show call graph (should fail):"
prof_callgraph

# Test 2: With call graph
puts "\n=========================================="
puts "Test 2: Profiling with call graph"
puts "=========================================="
prof_init -callgraph
prof_instrument_all
main
prof_summary

puts "\nCall Graph (Tree View):"
prof_callgraph

puts "\nExporting call graph to DOT format..."
prof_callgraph_dot "callgraph.dot"

puts "\n=========================================="
puts "Test Complete!"
puts "=========================================="
puts "Generated files:"
puts "  - callgraph.dot (use: dot -Tpng callgraph.dot -o callgraph.png)"
puts "=========================================="
