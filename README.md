# Tcl Profiler - Complete User Guide

## 📋 Features

✅ **Call Count Statistics** - Find the most frequently called procs
✅ **Time Measurement** - Total Time vs Self Time
✅ **Top N Queries** - Quickly identify bottlenecks
✅ **Multiple Sorting Options** - Sort by count, time, or average
✅ **CSV Export** - For further analysis
✅ **Call Graph Visualization** - See the complete call hierarchy (optional)
✅ **DOT Export** - Generate call graphs for Graphviz
✅ **Low Overhead** - Based on rename, not trace (~10-15% extra with call graph)
✅ **No Source Modification Required** - Completely transparent

---

## 🚀 Quick Start

### Basic Usage (Without Call Graph)

```tcl
# 1. Load profiler
source tcl_profiler_complete.tcl

# 2. Load your script
source your_script.tcl

# 3. Initialize and instrument
prof_init
prof_instrument_all

# 4. Execute your program
run_your_main_function

# 5. View results
prof_summary
```

### With Call Graph (Track Call Hierarchy)

```tcl
# 1. Load profiler
source tcl_profiler_complete.tcl

# 2. Load your script
source your_script.tcl

# 3. Initialize with call graph enabled
prof_init -callgraph
prof_instrument_all

# 4. Execute your program
run_your_main_function

# 5. View results and call graph
prof_summary
prof_callgraph

# 6. Export call graph visualization
prof_callgraph_dot callgraph.dot
# Then: dot -Tpng callgraph.dot -o callgraph.png
```

---

## 📊 Core Concepts

### Total Time vs Self Time

**Important! This is the key to understanding profiler results**

```
Example:
proc A {} {
    # Own code takes 100ms
    B          # B takes 500ms
    C          # C takes 300ms
}

Result:
A's Total Time = 900ms (100 + 500 + 300)
A's Self Time  = 100ms (only its own code)
```

**Key Principles:**
- **High Total Time** → This proc and its children combined are slow
- **High Self Time** → This proc **itself** is the bottleneck ⚠️

**Optimization Recommendations:**
- Optimize procs with **highest Self Time** first
- They are the real bottlenecks
- Procs with high Total Time but low Self Time are not the priority

---

## 🎯 Use Cases

### Case 1: Find Most Frequently Called Procs

**Problem:** Don't know which proc is called most often

**Solution:**
```tcl
prof_top 10 count
```

**Example Output:**
```
Top 10 Most Called Procs:
============================================================
 1. get_cells
    Calls: 1234, Total: 5432.10ms, Self: 3210.50ms
 2. get_attribute
    Calls: 987, Total: 2345.67ms, Self: 2100.00ms
...
```

**If a proc is called too many times:**
- Check if it's being called repeatedly in a loop
- Consider caching results

---

### Case 2: Find Most Time-Consuming Procs

**Problem:** Script is slow, don't know where the bottleneck is

**Solution:**
```tcl
# First check total time
prof_top 10 total

# Then check self time (more important!)
prof_top 10 self
```

**Interpreting Results:**
```
If compile_ultra:
  Total Time = 98765ms
  Self Time  = 98765ms

→ compile_ultra itself is slow (it doesn't call other procs)
→ This is the real bottleneck


If run_synthesis:
  Total Time = 125000ms
  Self Time  = 100ms

→ run_synthesis itself is fast (only takes 100ms)
→ But the child procs it calls are slow
→ Should optimize the children, not run_synthesis
```

---

### Case 3: Complete Workflow Analysis

**Problem:** Need comprehensive performance overview

**Solution:**
```tcl
# 1. Quick summary
prof_summary

# 2. Full report (sorted by self time)
prof_report self

# 3. Export detailed data
prof_export analysis.csv
```

---

## 📊 Call Graph Visualization

### What is Call Graph?

Call Graph shows the **complete calling hierarchy** of your program:
- Which proc calls which
- How many times each call happens
- Visual representation of code flow

**Example Output:**
```
├─ main_flow (1 calls, 78.98ms)
│  ├─ run_analysis (2 calls, 61.88ms)
│  │  ├─ analyze_timing (2 calls, 31.73ms)
│  │     ├─ get_design_info (4 calls, 21.75ms)
│     ├─ analyze_area (2 calls, 30.07ms)
│        ├─ get_design_info (4 calls, 21.75ms)
   ├─ optimize_design (1 calls, 48.26ms)
      ├─ run_analysis (2 calls, 61.88ms)
```

### When to Use Call Graph

✅ **Understanding code flow** - See the execution path
✅ **Finding unexpected calls** - Discover who's calling what
✅ **Visualizing architecture** - See the proc hierarchy
✅ **Debugging complex flows** - Trace execution paths

### Performance Impact

Call Graph adds **minimal overhead**:
- ~10-15% extra overhead when enabled
- Still < 0.02% impact on procs > 100ms
- **Disabled by default** - zero impact when not used

### Tree View

```tcl
prof_init -callgraph
prof_instrument_all
# ... run your code ...
prof_callgraph
```

Shows hierarchical tree with:
- Call counts at each level
- Total time for each proc
- Indentation showing call depth

### DOT Export (Graphviz)

```tcl
prof_callgraph_dot "callgraph.dot"
```

Then visualize with Graphviz:
```bash
dot -Tpng callgraph.dot -o callgraph.png
```

Creates a visual graph showing:
- Nodes: Procs with their stats
- Edges: Call relationships with counts
- Easy to spot patterns and bottlenecks

---

## 🔧 Advanced Usage

### Instrument Only Specific Procs

```tcl
# Don't instrument everything, only what you care about
prof_init

prof_instrument run_synthesis
prof_instrument compile_ultra
prof_instrument place_opt
prof_instrument route_opt

# Execute
run_synthesis

# Report
prof_summary
```

**Advantages:**
- Lower overhead
- Cleaner output
- More focused

---

### Using in EDA Tools

#### Synopsys Design Compiler

```tcl
# In dc_shell
dc_shell> source tcl_profiler_complete.tcl
dc_shell> source my_synthesis_script.tcl
dc_shell> prof_init
dc_shell> prof_instrument_all
dc_shell>
dc_shell> # Run your flow
dc_shell> run_my_synthesis
dc_shell>
dc_shell> # View results
dc_shell> prof_summary
dc_shell> prof_top 10 self
```

#### Wrapper Script Approach

Create `run_with_profiling.tcl`:
```tcl
source tcl_profiler_complete.tcl
source my_original_script.tcl

prof_init
prof_instrument_all

# Execute original flow
main_synthesis_flow

# Auto-generate reports
prof_summary
prof_report self
prof_export synthesis_profile.csv
```

Execute:
```bash
dc_shell -f run_with_profiling.tcl | tee synthesis_with_profile.log
```

---

## 📈 Interpreting Reports

### Summary Report

```
==========================================
Profiler Summary
==========================================
Most Called Proc:
  get_cells (1234 times)              ← Most frequently called

Most Time-Consuming Proc (Total Time):
  run_synthesis (125634.56ms)         ← Longest total time

Most Time-Consuming Proc (Self Time):
  compile_ultra (98765.43ms)          ← Real bottleneck!
  ⚠️  This is the real bottleneck!
```

**Interpretation:**
1. `get_cells` called 1234 times → Might be in a loop, consider caching
2. `run_synthesis` has longest total time → But this is the main function, normal
3. `compile_ultra` has longest self time → **This is what to optimize**

---

### Full Report Interpretation

```
Proc Name                           Calls      Total(ms)       Self(ms)        Avg(ms)      Min(us)      Max(us)
------------------------------------------------------------------------------------------------------------------------
compile_ultra                           1       98765.43       98765.43       98765.43      98765430     98765430
get_cells                            1234        5432.10        3210.50           4.40          1000        50000
get_attribute                         987        2345.67        2100.00           2.38           500        10000
```

**Column Meanings:**
- **Calls**: Number of invocations
- **Total(ms)**: Total execution time (including children)
- **Self(ms)**: Self execution time (excluding children) ⭐ Most important
- **Avg(ms)**: Average time per call
- **Min(us)**: Fastest single call
- **Max(us)**: Slowest single call

**Optimization Priority:**
1. Highest Self Time → Priority
2. Many Calls with non-trivial Avg → Secondary
3. High Total Time but low Self Time → Not urgent

---

## 🎨 Real-World Examples

### Example: Discovering Repeated Queries in a Loop

**Before profiling:**
```tcl
proc process_cells {} {
    foreach cell [get_cells *] {
        set clocks [get_clocks]      # ← Repeated query!
        # ... process ...
    }
}
```

**Profiler Result:**
```
get_clocks - Calls: 10000 times
→ Discovered get_clocks was called 10000 times!
```

**Optimization:**
```tcl
proc process_cells {} {
    set clocks [get_clocks]          # ← Move outside, query only once
    foreach cell [get_cells *] {
        # Use $clocks
    }
}
```

**Result:**
```
Before: get_clocks - 10000 calls, 5000ms
After:  get_clocks - 1 call, 0.5ms
→ 10000x faster!
```

---

### Example: Finding the Real Bottleneck

**Profiler Result:**
```
Proc Name           Calls    Total(ms)    Self(ms)
run_flow               1      120000       100
  setup               1       10000        50
  synthesis           1      100000      99950    ← Bottleneck is here!
  place_route         1       10000        50
```

**Interpretation:**
- `run_flow` has long Total Time, but short Self Time
  → `run_flow` itself is not slow, its children are

- `synthesis` has high Self Time
  → **This is what to optimize**

**Don't optimize `run_flow`, optimize `synthesis`!**

---

## 💾 CSV Export and Further Analysis

### Export CSV

```tcl
prof_export profile.csv
```

### CSV Format

```csv
Proc,Calls,Total(us),Self(us),Avg(us),Min(us),Max(us)
compile_ultra,1,98765430,98765430,98765430,98765430,98765430
get_cells,1234,5432100,3210500,4402,1000,50000
```

### Analyze with Python

```python
import pandas as pd

df = pd.read_csv('profile.csv')

# Find top 10 by Self Time
top_bottlenecks = df.nlargest(10, 'Self(us)')
print(top_bottlenecks)

# Find most called
most_called = df.nlargest(10, 'Calls')
print(most_called)

# Visualize
import matplotlib.pyplot as plt
df.plot(x='Proc', y='Self(us)', kind='bar')
plt.show()
```

---

## ⚡ Performance Considerations

### Overhead Analysis

- **Overhead per proc call: ~0.01ms**
- **For procs with execution time > 100ms: Impact < 0.01%**
- **For procs with execution time > 10ms: Impact < 0.1%**
- **For procs with execution time < 1ms: May have 1-10% impact**

### Reducing Overhead

```tcl
# Method 1: Only instrument slow procs
prof_instrument compile_ultra
prof_instrument place_opt
# Don't instrument fast helper functions

# Method 2: Staged profiling
# Round 1: Instrument everything, find main bottlenecks
# Round 2: Only instrument bottleneck area, measure precisely
```

---

## 🐛 Troubleshooting

### Issue 1: "proc XXX does not exist"

**Cause:** Trying to instrument before proc is defined

**Solution:**
```tcl
# Wrong order
prof_init
prof_instrument_all    # ← Procs not defined yet!
source my_script.tcl

# Correct order
source my_script.tcl   # ← Load first, define procs
prof_init
prof_instrument_all    # ← Then instrument
```

---

### Issue 2: Seeing Many System Procs

**Cause:** Instrumented Tcl built-in procs

**Solution:**
Profiler already filters most system procs. If you still see strange procs:

```tcl
# Manually instrument specific procs
prof_init
prof_instrument my_proc1
prof_instrument my_proc2
# Don't use prof_instrument_all
```

---

### Issue 3: Negative Self Time

**Cause:** Timing precision issues (very rare)

**Solution:** Can be ignored, or re-run

---

## 📚 Command Reference

### Initialization
```tcl
prof_init                         # Initialize without call graph
prof_init -callgraph             # Initialize with call graph tracking
```

### Instrumentation
```tcl
prof_instrument <proc_name>       # Instrument single proc
prof_instrument_all               # Instrument all user-defined procs
```

### Reports
```tcl
prof_summary                      # Quick summary
prof_top <n> <sort>              # Top N (sort: count/total/self)
prof_report <sort>               # Full report (sort: count/total/self/avg)
prof_export <filename>           # Export CSV
```

### Call Graph (requires -callgraph)
```tcl
prof_callgraph                    # Show call graph tree view
prof_callgraph_dot <filename>    # Export call graph in DOT format
```

### Sort Options
- `count` - Sort by call count
- `total` - Sort by total time
- `self` - Sort by self time ⭐ Recommended
- `avg` - Sort by average time

---

## 🎯 Best Practices

### 1. Start with Summary for Quick Overview

```tcl
prof_summary
```
See what's most frequently called and most time-consuming

### 2. Use Top to Focus on Key Issues

```tcl
prof_top 10 self    # Real bottlenecks
prof_top 10 count   # Check for repeated calls
```

### 3. Use Report for Complete Data

```tcl
prof_report self
```

### 4. Export for Further Analysis

```tcl
prof_export analysis.csv
```

### 5. Re-measure After Optimization

```tcl
prof_init           # Reset
# ... run optimized code ...
prof_summary        # Compare results
```

---

## 🚀 Workflow Integration

### Development Phase
```tcl
# Run after each modification
source profiler.tcl
source my_script.tcl
prof_init
prof_instrument_all
run_tests
prof_summary
```

### CI/CD Integration
```bash
#!/bin/bash
# run_with_profiling.sh

dc_shell -f << EOF
source tcl_profiler_complete.tcl
source synthesis.tcl
prof_init
prof_instrument_all
run_synthesis
prof_export ci_profile.csv
exit
EOF

# Check for performance regression
python check_performance_regression.py ci_profile.csv baseline.csv
```

---

## 📞 Support and Feedback

This profiler is an open-source tool and can be customized to your needs.

If you need new features, you can directly modify `tcl_profiler_complete.tcl`.

---

**Happy Profiling! 🎉**
