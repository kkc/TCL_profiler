#!/usr/bin/env tclsh
# Complete Tcl Profiler
# Features:
# - Track call counts
# - Track total time and self time
# - Top N queries
# - Multiple sorting options
# - CSV export

namespace eval ::profiler {
    variable enabled 1
    variable depth 0
    variable call_stack {}

    # Statistics data
    variable stats
    array set stats {}

    # Start time for each call
    variable start_times
    array set start_times {}
}

proc ::profiler::init {} {
    variable stats
    variable enabled
    
    array unset stats
    array set stats {}
    set enabled 1
    
    puts "Profiler initialized"
}

proc ::profiler::instrument {proc_name} {
    # Check if already instrumented
    if {[info procs ::__orig_$proc_name] ne ""} {
        return
    }

    # Check if proc exists
    if {[info procs ::$proc_name] eq ""} {
        puts "Warning: proc $proc_name does not exist"
        return
    }

    # Rename original proc
    rename ::$proc_name ::__orig_$proc_name

    # Create wrapper
    proc ::$proc_name {args} "
        ::profiler::enter [list $proc_name]

        set __code \[catch {
            uplevel 1 ::__orig_$proc_name \$args
        } __result __options\]

        ::profiler::exit [list $proc_name]

        return -options \$__options \$__result
    "
}

proc ::profiler::enter {proc_name} {
    variable enabled
    variable depth
    variable call_stack
    variable start_times
    variable stats

    if {!$enabled} return

    # Record entry time
    set now [clock microseconds]
    set start_times($depth) $now

    # Add to call stack
    lappend call_stack $proc_name

    # Initialize statistics
    if {![info exists stats($proc_name)]} {
        set stats($proc_name) [dict create \
            count 0 \
            total_time 0 \
            self_time 0 \
            min_time 999999999 \
            max_time 0 \
            children_time 0]
    }

    incr depth
}

proc ::profiler::exit {proc_name} {
    variable enabled
    variable depth
    variable call_stack
    variable start_times
    variable stats

    if {!$enabled} return

    incr depth -1

    # Calculate execution time
    set end_time [clock microseconds]
    set start_time $start_times($depth)
    set duration [expr {$end_time - $start_time}]

    # Update statistics
    dict incr stats($proc_name) count
    dict incr stats($proc_name) total_time $duration

    # Update min/max
    set min [dict get $stats($proc_name) min_time]
    set max [dict get $stats($proc_name) max_time]
    if {$duration < $min} {
        dict set stats($proc_name) min_time $duration
    }
    if {$duration > $max} {
        dict set stats($proc_name) max_time $duration
    }

    # Remove from call stack
    set call_stack [lrange $call_stack 0 end-1]

    # If has parent, update parent's children_time
    if {[llength $call_stack] > 0} {
        set parent [lindex $call_stack end]
        dict incr stats($parent) children_time $duration
    }
}

proc ::profiler::compute_self_time {} {
    variable stats
    
    foreach proc_name [array names stats] {
        set total [dict get $stats($proc_name) total_time]
        set children [dict get $stats($proc_name) children_time]
        set self [expr {$total - $children}]
        dict set stats($proc_name) self_time $self
    }
}

proc ::profiler::report {{sort_by "total"}} {
    variable stats

    # Compute self time
    compute_self_time

    puts "\n=========================================="
    puts "Profiler Report"
    puts "=========================================="

    if {[array size stats] == 0} {
        puts "No data collected."
        return
    }

    # Prepare data
    set data {}
    foreach {proc_name stat_dict} [array get stats] {
        set count [dict get $stat_dict count]
        set total [dict get $stat_dict total_time]
        set self [dict get $stat_dict self_time]
        set min [dict get $stat_dict min_time]
        set max [dict get $stat_dict max_time]
        set avg [expr {$count > 0 ? $total / $count : 0}]

        lappend data [list $proc_name $count $total $self $avg $min $max]
    }

    # Sort
    switch $sort_by {
        "count" {
            set data [lsort -integer -decreasing -index 1 $data]
            set header "Sorted by: Call Count"
        }
        "total" {
            set data [lsort -integer -decreasing -index 2 $data]
            set header "Sorted by: Total Time"
        }
        "self" {
            set data [lsort -integer -decreasing -index 3 $data]
            set header "Sorted by: Self Time"
        }
        "avg" {
            set data [lsort -real -decreasing -index 4 $data]
            set header "Sorted by: Average Time"
        }
        default {
            set header "Unsorted"
        }
    }

    puts $header
    puts ""

    # Print header
    puts [format "%-30s %10s %15s %15s %15s %12s %12s" \
        "Proc Name" "Calls" "Total(ms)" "Self(ms)" "Avg(ms)" "Min(us)" "Max(us)"]
    puts [string repeat "-" 120]

    # Print data
    set grand_total 0
    set grand_self 0
    foreach item $data {
        lassign $item proc_name count total self avg min max

        set total_ms [format "%.2f" [expr {$total / 1000.0}]]
        set self_ms [format "%.2f" [expr {$self / 1000.0}]]
        set avg_ms [format "%.2f" [expr {$avg / 1000.0}]]

        puts [format "%-30s %10d %15s %15s %15s %12d %12d" \
            $proc_name $count $total_ms $self_ms $avg_ms $min $max]

        incr grand_total $total
        incr grand_self $self
    }

    puts [string repeat "-" 120]
    set grand_total_ms [format "%.2f" [expr {$grand_total / 1000.0}]]
    set grand_self_ms [format "%.2f" [expr {$grand_self / 1000.0}]]
    puts [format "%-30s %10s %15s %15s" "TOTAL" "" $grand_total_ms $grand_self_ms]
    puts ""
}

proc ::profiler::top {n {sort_by "total"}} {
    variable stats

    compute_self_time

    # Prepare data
    set data {}
    foreach {proc_name stat_dict} [array get stats] {
        set count [dict get $stat_dict count]
        set total [dict get $stat_dict total_time]
        set self [dict get $stat_dict self_time]

        lappend data [list $proc_name $count $total $self]
    }

    # Sort
    switch $sort_by {
        "count" {
            set data [lsort -integer -decreasing -index 1 $data]
            set title "Top $n Most Called Procs"
        }
        "total" {
            set data [lsort -integer -decreasing -index 2 $data]
            set title "Top $n Most Time-Consuming Procs (Total Time)"
        }
        "self" {
            set data [lsort -integer -decreasing -index 3 $data]
            set title "Top $n Most Time-Consuming Procs (Self Time)"
        }
        default {
            set title "Top $n Procs"
        }
    }

    puts "\n$title:"
    puts [string repeat "=" 60]

    set count 0
    foreach item $data {
        lassign $item proc_name calls total self

        set total_ms [format "%.2f" [expr {$total / 1000.0}]]
        set self_ms [format "%.2f" [expr {$self / 1000.0}]]

        incr count
        puts "[format %2d $count]. $proc_name"
        puts "    Calls: $calls, Total: ${total_ms}ms, Self: ${self_ms}ms"

        if {$count >= $n} break
    }
    puts ""
}

proc ::profiler::summary {} {
    variable stats

    compute_self_time

    puts "\n=========================================="
    puts "Profiler Summary"
    puts "=========================================="

    if {[array size stats] == 0} {
        puts "No data collected."
        return
    }

    # Find most called proc
    set max_count 0
    set max_count_proc ""

    # Find most time-consuming proc (total)
    set max_total 0
    set max_total_proc ""

    # Find most time-consuming proc (self)
    set max_self 0
    set max_self_proc ""

    foreach {proc_name stat_dict} [array get stats] {
        set count [dict get $stat_dict count]
        set total [dict get $stat_dict total_time]
        set self [dict get $stat_dict self_time]

        if {$count > $max_count} {
            set max_count $count
            set max_count_proc $proc_name
        }

        if {$total > $max_total} {
            set max_total $total
            set max_total_proc $proc_name
        }

        if {$self > $max_self} {
            set max_self $self
            set max_self_proc $proc_name
        }
    }

    puts "Most Called Proc:"
    puts "  $max_count_proc ($max_count times)"
    puts ""

    puts "Most Time-Consuming Proc (Total Time):"
    puts "  $max_total_proc ([format %.2f [expr {$max_total/1000.0}]]ms)"
    puts ""

    puts "Most Time-Consuming Proc (Self Time):"
    puts "  $max_self_proc ([format %.2f [expr {$max_self/1000.0}]]ms)"
    puts "  ⚠️  This is the real bottleneck!"
    puts ""
}

proc ::profiler::export_csv {filename} {
    variable stats
    
    compute_self_time
    
    set fh [open $filename w]
    puts $fh "Proc,Calls,Total(us),Self(us),Avg(us),Min(us),Max(us)"
    
    foreach {proc_name stat_dict} [array get stats] {
        set count [dict get $stat_dict count]
        set total [dict get $stat_dict total_time]
        set self [dict get $stat_dict self_time]
        set min [dict get $stat_dict min_time]
        set max [dict get $stat_dict max_time]
        set avg [expr {$count > 0 ? $total / $count : 0}]
        
        puts $fh "$proc_name,$count,$total,$self,$avg,$min,$max"
    }
    
    close $fh
    puts "Exported to $filename"
}

# Automatically instrument all user-defined procs
proc ::profiler::instrument_all {} {
    # Important: Must use ::* to get procs from global namespace
    # Otherwise we get procs from current namespace (::profiler::)
    foreach proc_name [info procs ::*] {
        # Remove :: prefix
        set proc_name [string range $proc_name 2 end]

        # Skip system and profiler's own procs
        if {[string match "profiler::*" $proc_name]} continue
        if {[string match "__orig_*" $proc_name]} continue
        if {[string match "tcl*" $proc_name]} continue
        if {[string match "prof_*" $proc_name]} continue
        # Skip procs used internally by profiler (avoid infinite recursion)
        if {$proc_name in {clock history}} continue
        # Skip other system procs
        if {$proc_name in {unknown auto_load auto_import auto_execok auto_qualify auto_load_index}} continue

        instrument $proc_name
    }

    puts "Instrumented all user-defined procs"
}

# Export convenience commands to global namespace
namespace eval :: {
    proc prof_init {} {
        ::profiler::init
    }

    proc prof_instrument {proc_name} {
        ::profiler::instrument $proc_name
    }

    proc prof_instrument_all {} {
        ::profiler::instrument_all
    }

    proc prof_report {{sort "total"}} {
        ::profiler::report $sort
    }

    proc prof_top {n {sort "total"}} {
        ::profiler::top $n $sort
    }

    proc prof_summary {} {
        ::profiler::summary
    }

    proc prof_export {file} {
        ::profiler::export_csv $file
    }
}

puts "=============================================="
puts "Tcl Profiler Loaded Successfully"
puts "=============================================="
puts ""
puts "Available Commands:"
puts "  prof_init                  - Initialize profiler"
puts "  prof_instrument <proc>     - Instrument a specific proc"
puts "  prof_instrument_all        - Instrument all user procs"
puts "  prof_report ?sort?         - Show full report"
puts "                               sort options: total, self, count, avg"
puts "  prof_top <n> ?sort?        - Show top N procs"
puts "  prof_summary               - Show quick summary"
puts "  prof_export <file>         - Export to CSV"
puts ""
puts "Quick Start:"
puts "  1. source your_script.tcl"
puts "  2. prof_init"
puts "  3. prof_instrument_all"
puts "  4. # Run your code"
puts "  5. prof_summary"
puts "=============================================="
