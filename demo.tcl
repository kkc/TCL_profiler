#!/usr/bin/env tclsh
# Demo script to test the profiler

# Simulate some EDA-like procs

proc slow_operation {} {
    # Simulate a slow operation (inherently slow)
    after 50
    return "slow_result"
}

proc fast_operation {} {
    # Simulate a fast operation
    set result 0
    for {set i 0} {$i < 100} {incr i} {
        incr result $i
    }
    return $result
}

proc medium_operation {n} {
    # Simulate a medium-speed operation
    set result {}
    for {set i 0} {$i < $n} {incr i} {
        lappend result [expr {$i * $i}]
    }
    return $result
}

proc nested_call {} {
    # This proc calls other procs
    # Total time will be long, but Self time will be short
    fast_operation
    medium_operation 1000
    slow_operation
    return "nested_done"
}

proc frequently_called {} {
    # This will be called many times
    expr {1 + 1}
}

proc main_workflow {} {
    puts "\n=== Running Main Workflow ==="

    # Call various procs
    puts "Step 1: Fast operations"
    for {set i 0} {$i < 100} {incr i} {
        fast_operation
    }

    puts "Step 2: Frequent calls"
    for {set i 0} {$i < 500} {incr i} {
        frequently_called
    }

    puts "Step 3: Medium operations"
    medium_operation 100
    medium_operation 500
    medium_operation 1000

    puts "Step 4: Nested calls"
    nested_call
    nested_call

    puts "Step 5: Slow operations"
    slow_operation
    slow_operation

    puts "=== Workflow Complete ==="
}

# Main program
puts "=========================================="
puts "Profiler Demo"
puts "=========================================="

# Load profiler
source tcl_profiler_complete.tcl

# Initialize
prof_init

# Instrument all procs
prof_instrument_all

# Execute main workflow
main_workflow

# Display results
puts "\n"
puts "=========================================="
puts "RESULTS"
puts "=========================================="

# Quick summary
prof_summary

# Top 5 most called procs
prof_top 5 count

# Top 5 most time-consuming (total time)
prof_top 5 total

# Top 5 most time-consuming (self time) - real bottlenecks
prof_top 5 self

# Full report (sorted by self time)
prof_report self

# Export CSV
prof_export "profile_results.csv"

puts "\n=========================================="
puts "Analysis Complete!"
puts "Check profile_results.csv for detailed data"
puts "=========================================="
