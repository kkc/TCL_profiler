#!/usr/bin/env tclsh
# Demo script for call graph feature

# Simulate some EDA-like procs with clear hierarchy
proc get_design_info {} {
    after 5
    return "design_info"
}

proc analyze_timing {} {
    get_design_info
    after 10
    return "timing_ok"
}

proc analyze_area {} {
    get_design_info
    after 8
    return "area_ok"
}

proc run_analysis {} {
    analyze_timing
    analyze_area
    return "analysis_complete"
}

proc optimize_design {} {
    run_analysis
    after 15
    return "optimized"
}

proc main_flow {} {
    puts "Starting design flow..."
    optimize_design
    run_analysis
    puts "Flow complete!"
}

# Main program
puts "=========================================="
puts "Call Graph Demo"
puts "=========================================="

# Load profiler WITH call graph tracking
source tcl_profiler_complete.tcl

# Initialize with call graph enabled
prof_init -callgraph

# Instrument all procs
prof_instrument_all

# Execute workflow
main_flow

# Display results
puts "\n=========================================="
puts "RESULTS"
puts "=========================================="

# Standard summary
prof_summary

# Show call graph tree
prof_callgraph

# Export to DOT format
prof_callgraph_dot "design_flow_callgraph.dot"

# Also export CSV
prof_export "design_flow_profile.csv"

puts "\n=========================================="
puts "Files Generated:"
puts "  - design_flow_callgraph.dot"
puts "  - design_flow_profile.csv"
puts ""
puts "To visualize call graph:"
puts "  dot -Tpng design_flow_callgraph.dot -o callgraph.png"
puts "=========================================="
