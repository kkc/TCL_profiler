# Tcl Profiler - 完整使用指南

## 📋 功能特色

✅ **呼叫次數統計** - 找出最常被呼叫的 proc
✅ **時間測量** - Total Time vs Self Time
✅ **Top N 查詢** - 快速找出瓶頸
✅ **多種排序** - 按次數、時間、平均值排序
✅ **CSV 匯出** - 供後續分析
✅ **低 Overhead** - 基於 rename，不是 trace
✅ **無需修改原始碼** - 完全透明

---

## 🚀 快速開始

### 最簡單的用法

```tcl
# 1. 載入 profiler
source tcl_profiler_complete.tcl

# 2. 載入你的腳本
source your_script.tcl

# 3. 初始化並 instrument
prof_init
prof_instrument_all

# 4. 執行你的程式
run_your_main_function

# 5. 查看結果
prof_summary
```

---

## 📊 核心概念

### Total Time vs Self Time

**重要！這是理解 profiler 結果的關鍵**

```
範例：
proc A {} {
    # 自己的程式碼花 100ms
    B          # B 花 500ms
    C          # C 花 300ms
}

結果：
A 的 Total Time = 900ms (100 + 500 + 300)
A 的 Self Time  = 100ms (只算自己)
```

**關鍵原則：**
- **Total Time 高** → 這個 proc 和它的子 proc 加起來很慢
- **Self Time 高** → 這個 proc **本身**就是瓶頸 ⚠️

**優化建議：**
- 先優化 **Self Time 最高**的 proc
- 它們才是真正的瓶頸
- Total Time 高但 Self Time 低的 proc 不是重點

---

## 🎯 使用場景

### 場景 1: 找出最常被呼叫的 proc

**問題：** 不知道哪個 proc 被呼叫最多次

**解決：**
```tcl
prof_top 10 count
```

**輸出範例：**
```
Top 10 Most Called Procs:
============================================================
 1. get_cells
    Calls: 1234, Total: 5432.10ms, Self: 3210.50ms
 2. get_attribute
    Calls: 987, Total: 2345.67ms, Self: 2100.00ms
...
```

**如果發現某個 proc 被呼叫過多次：**
- 檢查是否在迴圈中重複呼叫
- 考慮快取結果

---

### 場景 2: 找出最花時間的 proc

**問題：** 腳本很慢，不知道瓶頸在哪

**解決：**
```tcl
# 先看總時間
prof_top 10 total

# 再看自身時間（更重要！）
prof_top 10 self
```

**解讀結果：**
```
如果 compile_ultra:
  Total Time = 98765ms
  Self Time  = 98765ms
  
→ compile_ultra 本身就很慢（它沒呼叫其他 proc）
→ 這是真正的瓶頸


如果 run_synthesis:
  Total Time = 125000ms
  Self Time  = 100ms
  
→ run_synthesis 本身很快（只花 100ms）
→ 但它呼叫的子 proc 很慢
→ 應該去優化子 proc，不是 run_synthesis
```

---

### 場景 3: 完整分析整個流程

**問題：** 需要全面了解效能狀況

**解決：**
```tcl
# 1. 快速摘要
prof_summary

# 2. 完整報告（按 self time 排序）
prof_report self

# 3. 匯出詳細資料
prof_export analysis.csv
```

---

## 🔧 進階用法

### 只 instrument 特定的 proc

```tcl
# 不要 instrument 全部，只 instrument 你關心的
prof_init

prof_instrument run_synthesis
prof_instrument compile_ultra
prof_instrument place_opt
prof_instrument route_opt

# 執行
run_synthesis

# 報告
prof_summary
```

**優點：**
- Overhead 更低
- 輸出更乾淨
- 更專注

---

### 在 EDA 工具中使用

#### Synopsys Design Compiler

```tcl
# 在 dc_shell 中
dc_shell> source tcl_profiler_complete.tcl
dc_shell> source my_synthesis_script.tcl
dc_shell> prof_init
dc_shell> prof_instrument_all
dc_shell> 
dc_shell> # 執行你的流程
dc_shell> run_my_synthesis
dc_shell> 
dc_shell> # 查看結果
dc_shell> prof_summary
dc_shell> prof_top 10 self
```

#### 包裝腳本方式

創建 `run_with_profiling.tcl`:
```tcl
source tcl_profiler_complete.tcl
source my_original_script.tcl

prof_init
prof_instrument_all

# 執行原始流程
main_synthesis_flow

# 自動產生報告
prof_summary
prof_report self
prof_export synthesis_profile.csv
```

執行：
```bash
dc_shell -f run_with_profiling.tcl | tee synthesis_with_profile.log
```

---

## 📈 解讀報告

### Summary 報告

```
==========================================
Profiler Summary
==========================================
Most Called Proc:
  get_cells (1234 times)              ← 被呼叫最多次

Most Time-Consuming Proc (Total Time):
  run_synthesis (125634.56ms)         ← 總時間最長

Most Time-Consuming Proc (Self Time):
  compile_ultra (98765.43ms)          ← 真正的瓶頸！
  ⚠️  This is the real bottleneck!
```

**解讀：**
1. `get_cells` 被呼叫 1234 次 → 可能在迴圈中，考慮快取
2. `run_synthesis` 總時間最長 → 但這是主函數，正常
3. `compile_ultra` 自身時間最長 → **這才是真正要優化的**

---

### Full Report 解讀

```
Proc Name                           Calls      Total(ms)       Self(ms)        Avg(ms)      Min(us)      Max(us)
------------------------------------------------------------------------------------------------------------------------
compile_ultra                           1       98765.43       98765.43       98765.43      98765430     98765430
get_cells                            1234        5432.10        3210.50           4.40          1000        50000
get_attribute                         987        2345.67        2100.00           2.38           500        10000
```

**各欄位意義：**
- **Calls**: 呼叫次數
- **Total(ms)**: 總執行時間（含子 proc）
- **Self(ms)**: 自身執行時間（不含子 proc）⭐ 重點
- **Avg(ms)**: 平均每次呼叫的時間
- **Min(us)**: 最快的一次呼叫
- **Max(us)**: 最慢的一次呼叫

**優化優先順序：**
1. Self Time 最高的 → 優先
2. Calls 很多且 Avg 不低的 → 次要
3. Total Time 高但 Self Time 低的 → 不急

---

## 🎨 實際案例

### 案例：發現迴圈中的重複查詢

**Before profiling:**
```tcl
proc process_cells {} {
    foreach cell [get_cells *] {
        set clocks [get_clocks]      # ← 重複查詢！
        # ... 處理 ...
    }
}
```

**Profiler 結果：**
```
get_clocks - Calls: 10000 times
→ 發現 get_clocks 被呼叫了 10000 次！
```

**優化：**
```tcl
proc process_cells {} {
    set clocks [get_clocks]          # ← 移到外面，只查一次
    foreach cell [get_cells *] {
        # 使用 $clocks
    }
}
```

**結果：**
```
Before: get_clocks - 10000 calls, 5000ms
After:  get_clocks - 1 call, 0.5ms
→ 快了 10000 倍！
```

---

### 案例：發現真正的瓶頸

**Profiler 結果：**
```
Proc Name           Calls    Total(ms)    Self(ms)
run_flow               1      120000       100
  setup               1       10000        50
  synthesis           1      100000      99950    ← 瓶頸在這！
  place_route         1       10000        50
```

**解讀：**
- `run_flow` Total Time 很長，但 Self Time 很短
  → `run_flow` 本身不慢，是子函數慢
  
- `synthesis` Self Time 很高
  → **這才是真正要優化的**

**不要去優化 `run_flow`，要優化 `synthesis`！**

---

## 💾 CSV 匯出與後續分析

### 匯出 CSV

```tcl
prof_export profile.csv
```

### CSV 格式

```csv
Proc,Calls,Total(us),Self(us),Avg(us),Min(us),Max(us)
compile_ultra,1,98765430,98765430,98765430,98765430,98765430
get_cells,1234,5432100,3210500,4402,1000,50000
```

### 用 Python 分析

```python
import pandas as pd

df = pd.read_csv('profile.csv')

# 找出 Self Time 最高的前 10
top_bottlenecks = df.nlargest(10, 'Self(us)')
print(top_bottlenecks)

# 找出呼叫次數最多的
most_called = df.nlargest(10, 'Calls')
print(most_called)

# 視覺化
import matplotlib.pyplot as plt
df.plot(x='Proc', y='Self(us)', kind='bar')
plt.show()
```

---

## ⚡ 效能考量

### Overhead 分析

- **每次 proc 呼叫的 overhead: ~0.01ms**
- **對於執行時間 > 100ms 的 proc: 影響 < 0.01%**
- **對於執行時間 > 10ms 的 proc: 影響 < 0.1%**
- **對於執行時間 < 1ms 的 proc: 可能有 1-10% 影響**

### 減少 Overhead 的方法

```tcl
# 方法 1: 只 instrument 慢的 proc
prof_instrument compile_ultra
prof_instrument place_opt
# 不 instrument 快速的 helper functions

# 方法 2: 分階段 profiling
# 第一輪：instrument 全部，找出主要瓶頸
# 第二輪：只 instrument 瓶頸附近的 proc，精確測量
```

---

## 🐛 疑難排解

### 問題 1: "proc XXX does not exist"

**原因：** 在 proc 定義之前就嘗試 instrument

**解決：**
```tcl
# 錯誤順序
prof_init
prof_instrument_all    # ← 此時 proc 還沒定義！
source my_script.tcl

# 正確順序
source my_script.tcl   # ← 先載入，定義 proc
prof_init
prof_instrument_all    # ← 再 instrument
```

---

### 問題 2: 看到很多系統 proc

**原因：** Instrument 了 Tcl 內建的 proc

**解決：**
profiler 已經自動過濾掉大部分系統 proc，如果還是看到奇怪的 proc：

```tcl
# 手動 instrument 特定的 proc
prof_init
prof_instrument my_proc1
prof_instrument my_proc2
# 不要用 prof_instrument_all
```

---

### 問題 3: Self Time 是負數

**原因：** 時間測量的精度問題（極少發生）

**解決：** 可以忽略，或是重新執行一次

---

## 📚 命令參考

### 初始化
```tcl
prof_init
```

### Instrument
```tcl
prof_instrument <proc_name>       # Instrument 單一 proc
prof_instrument_all               # Instrument 所有 user-defined procs
```

### 報告
```tcl
prof_summary                      # 快速摘要
prof_top <n> <sort>              # Top N (sort: count/total/self)
prof_report <sort>               # 完整報告 (sort: count/total/self/avg)
prof_export <filename>           # 匯出 CSV
```

### 排序選項
- `count` - 按呼叫次數排序
- `total` - 按總時間排序
- `self` - 按自身時間排序 ⭐ 推薦
- `avg` - 按平均時間排序

---

## 🎯 最佳實踐

### 1. 先用 summary 快速了解

```tcl
prof_summary
```
看看最常被呼叫、最花時間的是哪些

### 2. 用 top 聚焦關鍵問題

```tcl
prof_top 10 self    # 真正的瓶頸
prof_top 10 count   # 是否有重複呼叫
```

### 3. 用 report 看完整資料

```tcl
prof_report self
```

### 4. 匯出後續分析

```tcl
prof_export analysis.csv
```

### 5. 優化後重新測量

```tcl
prof_init           # 重置
# ... 執行優化後的程式碼 ...
prof_summary        # 比較結果
```

---

## 🚀 整合到工作流程

### 開發階段
```tcl
# 每次修改後都跑一次
source profiler.tcl
source my_script.tcl
prof_init
prof_instrument_all
run_tests
prof_summary
```

### CI/CD 整合
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

# 檢查是否有效能退化
python check_performance_regression.py ci_profile.csv baseline.csv
```

---

## 📞 支援與回饋

這個 profiler 是開源工具，可以根據你的需求客製化。

如果需要新功能，可以直接修改 `tcl_profiler_complete.tcl`。

---

**Happy Profiling! 🎉**
