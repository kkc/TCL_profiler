#!/usr/bin/env tclsh
# Demo script to test the profiler

# 模擬一些 EDA-like procs

proc slow_operation {} {
    # 模擬一個慢操作（自己就很慢）
    after 50
    return "slow_result"
}

proc fast_operation {} {
    # 模擬一個快操作
    set result 0
    for {set i 0} {$i < 100} {incr i} {
        incr result $i
    }
    return $result
}

proc medium_operation {n} {
    # 模擬中等速度的操作
    set result {}
    for {set i 0} {$i < $n} {incr i} {
        lappend result [expr {$i * $i}]
    }
    return $result
}

proc nested_call {} {
    # 這個 proc 呼叫其他 proc
    # Total time 會很長，但 Self time 很短
    fast_operation
    medium_operation 1000
    slow_operation
    return "nested_done"
}

proc frequently_called {} {
    # 這個會被呼叫很多次
    expr {1 + 1}
}

proc main_workflow {} {
    puts "\n=== Running Main Workflow ==="
    
    # 呼叫各種 proc
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

# 主程式
puts "=========================================="
puts "Profiler Demo"
puts "=========================================="

# 載入 profiler
source tcl_profiler_complete.tcl

# 初始化
prof_init

# Instrument 所有 proc
prof_instrument_all

# 執行主要流程
main_workflow

# 顯示結果
puts "\n"
puts "=========================================="
puts "RESULTS"
puts "=========================================="

# 快速摘要
prof_summary

# Top 5 最常被呼叫
prof_top 5 count

# Top 5 最花時間（總時間）
prof_top 5 total

# Top 5 最花時間（自身時間）- 真正的瓶頸
prof_top 5 self

# 完整報告（按 self time 排序）
prof_report self

# 匯出 CSV
prof_export "profile_results.csv"

puts "\n=========================================="
puts "Analysis Complete!"
puts "Check profile_results.csv for detailed data"
puts "=========================================="
