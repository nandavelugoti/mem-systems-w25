+++
title = "End to End Sequential Consistency"
[extra]
bio = """
  [Sami Aljabery] is a graduate student studying Electrical and Computer Engineering at Oregon State University. He's passionate about computer architecture, loves exploring, and enjoys the Metroid series.
"""
[[extra.authors]]
name = "Sami Aljabery"
[[extra.authors]]
name = "Gabriel Rodgers (Scribe) "
[[extra.authors]]
name = "Noah Bean (Blogger) "
+++

## Introduction

This blog post covers End-to-End Sequential Consistency, a research paper published on June 13, 2012, and presented in our group on January 29, 2025. The paper tackles the challenge of making Sequential Consistency (SC) efficient enough for real-world use. While SC ensures a clear, intuitive execution order for multi-threaded programs, its strict memory ordering usually comes with a steep performance hit. To address this, the authors propose a low-overhead SC implementation that combines compiler optimizations and lightweight hardware modifications. Their approach classifies memory accesses as "safe" (private or read-only) or "unsafe" (shared and writable), allowing most operations to bypass SC constraints. Benchmarks show that this hybrid approach incurs only a 6.2% overhead compared to TSO hardware, which suggest that end-to-end SC might be more practical than previously thought.

## Background and Context

Modern multiprocessors use weak memory consistency models like Total Store Order (TSO) and Relaxed Memory Order (RMO) to boost performance by reordering memory operations, which makes multi-threaded programming harder to reason about. Sequential Consistency (SC) offers a much simpler model by ensuring all memory operations appear in a globally ordered sequence, but enforcing this model dampens performance. Compilers and processors further complicate things by reordering instructions to optimize execution, meaning SC isn't naturally preserved. To ensure correctness, programmers typically rely on locks, memory fences, and atomic operations, which add complexity and slow things down.

## Keywords

#### Memory Consistency Model
Defines how memory operations (reads/writes) appear across threads in a multiprocessor system, impacting parallel program behavior and performance.

#### Sequential Consistency (SC)
A strict memory model where operations execute in program order and all threads see a single global order. Improves predictability but hurts performance.

#### Total Store Order (TSO)
A weaker model  that allows loads to execute before earlier stores complete, improving speed while maintaining store ordering for consistency.

#### Relaxed Memory Order (RMO)
A high-performance model that allows both loads and stores to be reordered, requiring explicit synchronization to maintain correctness.

#### Thread-Local Memory
Memory only accessed by a single thread, avoiding synchronization overhead and allowing SC optimizations by skipping ordering constraints.

Shared Read-Only Memory\
Data readable but not writable by multiple threads. Since it never changes, it doesn't require strict ordering, allowing SC optimizations.

#### Store Buffer
A hardware queue that holds pending stores before committing to memory. Improves performance but can break SC if loads execute before previous stores complete.

#### FIFO Store Buffer
A First-In-First-Out buffer that preserves store order for shared memory, enforcing SC only where necessary.

#### Out-of-Order Execution (OoOE)
A CPU optimization that executes instructions as soon as dependencies are ready, improving performance but requiring memory ordering mechanisms to enforce SC.

#### Static Analysis
A compile-time optimization where LLVM detects thread-local and read-only accesses, marking them as safe for SC efficiency.

#### Dynamic Analysis
A runtime optimization where the OS tracks memory sharing and updates classifications, preventing unnecessary SC enforcement.

#### LLVM Compiler Framework
An open-source compiler infrastructure modified to classify memory accesses and ensure SC is preserved without unnecessary performance loss.

## Summary of the Paper

## 1\. Introduction

Memory consistency models define how multi-threaded programs interact with memory, balancing programmer simplicity with system performance. Sequential Consistency (SC) is one of the strongest models, enforcing a global order of memory operations, but its strict constraints limit compiler and hardware optimizations, making it costly to implement efficiently. 

This paper proposes a practical SC hardware design that avoids speculation by recognizing that most memory accesses are private or shared read-only, meaning SC constraints aren't always necessary. By classifying memory accesses at compile time and runtime, SC enforcement is applied only when needed. The design splits the store buffer into a FIFO buffer for shared writes and an unordered buffer for private writes, reducing stalls and improving efficiency. Results show only a 6.2% overhead compared to TSO, making SC enforcement viable for modern processors.

## 2\. Background

Most programming languages only guarantee SC for data-race-free programs, but many real-world programs contain data races, intentional or not. Modern compilers violate SC through optimizations like instruction reordering, which is why languages use weak memory models. However, research shows that an SC-preserving LLVM compiler can retain most optimizations while keeping overhead low (~3.8%). Running these SC-safe binaries on SC hardware would provide end-to-end SC enforcement.

Designing efficient SC hardware remains a challenge because naive SC forces strict ordering, severely limiting performance. Existing approaches rely on complex speculation and rollback mechanisms, which are costly and difficult to implement. 

## 3\. Relaxing Memory Model Constraints for Safe Accesses

Many memory operations, such as thread-local or shared read-only accesses, do not require strict ordering since they cannot be observed or altered by other threads. If the compiler or runtime system can guarantee an access is safe, the processor can freely reorder it, improving performance without violating SC.

## 4\. Design: Memory Access Type Driven SC Hardware

The proposed SC hardware optimizes memory ordering by classifying accesses as safe or unsafe. This classification is determined through a hybrid approach: static compiler analysis, which flags function-local and read-only accesses, and dynamic runtime analysis, which tracks page-level access patterns via the OS and MMU. If either method deems an access safe, SC constraints are relaxed, minimizing performance overhead.

To further improve efficiency, the store buffer is split into two parts: a FIFO buffer for unsafe stores (preserving order) and an unordered buffer for safe stores (allowing faster execution). This setup lets safe loads commit without waiting for stores. 

## 5\. Static Classification of Memory Accesses

The compiler classifies memory accesses as safe (private or read-only shared) or unsafe (shared writeable) and marks them accordingly in machine code. Safe accesses can be reordered, while unsafe ones must follow SC constraints. Function-local, non-escaping variables and literals are classified as safe, while global, heap-allocated, and escaped variables are unsafe. To maintain correctness, any instruction that accesses both safe and unsafe variables is marked as unsafe. This static analysis is conservative but avoids the runtime costs of page-level tracking.

To ensure correct store-to-load forwarding, loads and stores to the same address must have the same classification. The processor performs an extra check before committing a store to avoid conflicts when different functions reuse stack locations. This ensures safe and unsafe stores do not execute out of order. Union variables are always marked unsafe, as aliasing complicates classification. In CISC architectures, memory instructions can access multiple variables, so the ISA is extended to store separate safety bits for each memory operand, ensuring proper classification at the micro-operation level.

## 6\. Dynamic Classification of Memory Accesses

Since static classification is conservative, a dynamic approach leverages the Memory Management Unit (MMU) and OS page protection to track memory access patterns at runtime. Pages are classified as private, shared read-only, or shared read-write, with only the last requiring strict SC enforcement. The Translation Lookaside Buffer (TLB) is extended with a safe bit to quickly determine if an access is safe. If either static or dynamic classification marks an access as safe, SC constraints are relaxed, reducing performance overhead.

Page states transition dynamically based on access patterns. A new page starts as "untouched", and the first access sets it as private. If another thread reads it, it becomes shared read-only, and if written to by multiple threads, it transitions to shared read-write, requiring strict SC. Inter-processor interrupts (IPIs) ensure memory ordering during transitions, invalidating TLB entries and flushing store buffers. TLB entries are reset on context switches to maintain correctness, and Direct Memory Access (DMA) interactions are managed by either enforcing exclusive access or temporarily marking affected pages as unsafe. 

## 7\. Results

The proposed SC-hybrid hardware reduces the overhead of enforcing Sequential Consistency (SC) to just 2.0% on average, a significant improvement over the 9.1% overhead of baseline SC. Worst-case overhead is 5.4% (facesim) compared to 28.8% in the baseline SC design. The hybrid classification approach, which combines static compiler analysis and dynamic page-based classification, achieves 71.5% accuracy, close to the 81.5% of an ideal byte-level scheme. End-to-end SC enforcement, including both compiler and hardware constraints, incurs a 6.2% overhead compared to a traditional TSO processor running a stock compiler, far lower than the 12.7% cost of naive SC. Store buffer optimizations ensure minimal additional hardware cost, with only a 1% increase in overhead when buffer sizes are reduced. 

#### Important Results

-   This paper demonstrates that Sequential Consistency (SC) can be enforced efficiently by selectively applying memory constraints only where necessary, reducing overhead without complex speculation.

-   Instead of enforcing strict SC for all memory accesses, the approach classifies them as safe (thread-local or shared read-only) or unsafe (shared writeable) by using a hybrid classification method, avoiding unnecessary stalls for 81% of accesses.

-   Results show that the SC-hybrid design incurs just 2.0% overhead over TSO, while full end-to-end SC (compiler + hardware) adds only 6.2%, far lower than naive SC's 12.7% penalty. Benchmarks confirm near-TSO performance, with worst-case overhead at 5.4% (facesim) vs. 28.8% in naive SC.

## Strengths and Weaknesses

#### Strengths

1.  Efficient SC Enforcement with Minimal Overhead\
    Achieves end-to-end SC with just 6.2% overhead, significantly lower than traditional SC implementations (~12.7%). Avoids speculative execution, making it simpler and more power-efficient than past SC approaches.

2.  Dual-Buffer Store Architecture\
    Introduces a FIFO + Unordered Store Buffer system, reducing stalls and improving efficiency. 

3.  Hybrid Memory Classification (Compiler + Runtime)\
    Combines static compiler analysis (LLVM-based) with dynamic runtime tracking (MMU & page tables) to accurately classify memory accesses with minimal overhead.

#### Weaknesses

1.  Limited Applicability Beyond x86\
    Designed for TSO-based architectures (like x86), which already enforce relatively strong memory consistency. Adoption in weaker memory models like ARM is uncertain, as they rely more on relaxed consistency.

2.  Reliance on OS Support for Runtime Classification\
    Requires OS modifications for tracking memory access types, which may limit adoption on existing systems.

3.  Evaluation Based on Simulation, Not Real Hardware\
    All results are from a Simics-based simulator, not real hardware. Without FPGA or ASIC testing, real-world feasibility remains uncertain.

## Class Discussion:

### 1.  What are some architectures that prioritize performance over programming ease of use?

Some architectures sacrifice ease of programming for raw performance, making them powerful but difficult to work with.

-   IBM's Cell processor (used in the PS3) had manual workload distribution and memory management, making it fast but developer-unfriendly. 

-   Intel's Itanium relied on compiler-managed parallelism (EPIC), which hurt adoption due to compiler complexity.

-   Intel Xeon Phi -- Optimized for massively parallel workloads, but required special programming models.

-   VLIW Processors -- Found in early GPUs/DSPs, demanded precise instruction scheduling.

-   RISC-V Vector Extensions -- Powerful but requires manual low-level management.

### 2.  Balance between sequential consistency and understandability of architecture/code?

There's a trade-off between sequential consistency (SC) and system understandability. SC makes multi-threaded code easier to reason about, but it restricts optimizations, slowing down execution. On the other hand, weaker memory models allow better performance but make debugging concurrency issues much harder.

In reality, only a small percentage of code actually requires strong consistency---most programs don't frequently share stores between processors. For these cases, weaker memory models (like TSO or RC) are a better fit, as they allow higher performance without unnecessary synchronization overhead. 

### 3.  Multiprocessors work in lockstep? How do they synchronize instructions/faulty instructions?

Multiprocessors do not operate in lockstep---each core runs independently, and there are no guarantees that instructions will execute at the same time across all cores. Some cores may run at different speeds due to frequency scaling, thermal constraints, or workload differences, but this doesn't matter for applications that don't share data.For high-performance computing (HPC) workloads, where synchronization is critical, frequency scaling is often disabled, ensuring all cores run at a fixed speed to avoid performance variation and keep parallel computations aligned.

### 4.  Shared page can be unsafe?

A shared memory page can be unsafe because it might contain both safe (thread-local or read-only) and unsafe (shared writeable) accesses. This makes it difficult to blindly treat an entire page as safe, as a single writeable access can break consistency guarantees. To handle this, a Finite State Machine (FSM) can track and dynamically classify memory accesses at the page level. The FSM can adjust permissions and enforcement rules based on how a page is being accessed.

### 5.  What platform did they use to run these benchmarks?

The benchmarks were run on a simulated platform, not real hardware. The authors used a Simex processor simulator, which started with an x86 core and was modified to support their SC-aware optimizations. They also implemented a modified LLVM compiler to classify memory accesses as safe or unsafe, integrating their approach into the software stack. The evaluation included Apache server benchmarks alongside PARSEC and SPLASH-2, representing real-world multi-threaded workloads. 

### 6.  Instructions xyz (in diff threads) can map to the same physical location - what does it mean, when can it happen?

In multi-threaded programs, different threads can have instructions that access the same physical memory location, even if they use different virtual addresses. This can lead to unexpected memory interactions and potential safety issues.

### 7.  Has this been implemented anywhere (in actual hardware)?

This approach has not been implemented in actual hardware. The paper was published in 2012, and there are no known commercial processors that have adopted this exact SC enforcement method. One major reason is that industry is slow to adopt changes that fundamentally alter core architecture. Implementing end-to-end SC enforcement requires modifications to hardware, compilers, operating systems, and programming models, making it a massive undertaking with uncertain incentives. Given that weak memory models already work well for performance, most companies don't see a strong reason to switch.

### 8.  Implementation in RISC-V and ARM?

This approach could be interesting for RISC-V, as it supports multiple consistency models, allowing flexibility in experimenting with SC enforcement. However, ARM relies on weak consistency for performance and efficiency, making it unlikely to adopt a strict SC model, especially since its OS ecosystem is already optimized for relaxed consistency models. 

### 9.  Challenges with Page Table Approach?

One issue with enforcing SC at the page level is that each page (typically 4KB) may contain both safe and unsafe data. If one part of the page needs strict SC while another doesn't, the system would have to either enforce SC on the whole page (wasting performance) or split memory in a way that increases complexity. In many cases, the amount of mixed safe/unsafe data in a page might not justify the overhead of tracking and enforcing SC at that granularity. 

### 10.  Better implementation - would have done analysis on the page table?

A more refined approach would involve deeper analysis at the page table level, ensuring that only truly shared read-write memory gets SC enforcement. Instead of enforcing SC on entire pages, the system could track memory regions at a finer granularity, reducing unnecessary constraints. A more efficient solution would involve adaptive tracking, ensuring that SC is only applied where actual shared modifications occur, rather than blindly enforcing it at the entire page level. This would help balance performance and correctness while minimizing unintended synchronization overhead.

### 11.  What about the language? Mem addr can escape thread and be used in a diff thread; are there languages that prevent this?

Certain programming languages prevent unsafe memory escapes between threads, making sequential consistency (SC) enforcement easier. Rust, for example, enforces strict ownership and borrowing rules, ensuring that a memory address cannot be accessed by multiple threads unless explicitly marked as safe. This paper was likely ahead of its time since escape analysis was still an evolving concept when this paper was written. Detecting whether a memory address escapes a thread is extremely difficult and requires deep compiler analysis, which is impossible to get 100% correct in many cases.

### 12.  What was this done in?

The implementation was primarily written in C++ using a modified LLVM compiler to classify memory accesses as safe or unsafe. Since LLVM is widely used for compiler research, this choice allowed fine-grained control over instruction ordering and optimization passes.

### 13.  Memory models - how a programmer works with it is important?

Memory models define how programmers interact with memory in multi-threaded programs, and Sequential Consistency (SC) is particularly frustrating because it restricts compiler and hardware optimizations. At the compiler level, memory ordering isn't fixed because optimizations like instruction reordering can change consistency guarantees. If the compiler doesn't explicitly enforce SC, it can freely reorder operations unless memory barriers or synchronization primitives are used. This leads to issues with undefined behavior, where the compiler assumes it can optimize memory accesses however it wants unless explicitly told otherwise. 

### 14.  What are the benefits of SC?

The main advantage of SC is that it makes multi-threaded programming easier to understand. Since memory operations appear in a global, ordered sequence, programmers don't have to worry about unexpected reordering by the compiler or hardware, making debugging and reasoning about concurrency much simpler.

### 15.  Analyzing the Graphs and Performance Trends

Shared vs. Unshared Data Performance

If the paper's claims hold, workloads with more shared data should perform better under the proposed SC model compared to naive SC. The results should show a clear gap between naive SC (SC-baseline) and the optimized SC-hybrid approach, especially for programs that frequently share memory between threads.

Which Workload Should Perform Best?

From the benchmarks, Barnes has the most shared data, so it should see the biggest performance improvement. However, in Streamcluster, the SC-Ideal case performs better than SC-Hybrid, raising questions about whether SC-Hybrid is fully optimizing memory accesses as expected.

## Interpreting SC-Ideal

The SC-Ideal case likely represents a perfect scenario where SC enforcement incurs zero penalties, serving as a best-case theoretical performance bound. The inclusion of "(byte)" in SC-Ideal's title is unclear---possibly indicating a byte-granularity analysis, but the paper should clarify its significance.

## Visualization Issues

One clear flaw in the presentation is poor graph design---everything is in grayscale, making it harder to distinguish between datasets. Modern conference guidelines recommend using color and patterns to improve readability, so the authors should refine their visualization for better clarity.

## Reevaluating Multiprocessing Through the SC Lens

SC assumes that shared memory is the common case, enforcing strict ordering to maintain consistency. However, real-world workloads often show the opposite---the majority of memory accesses are thread-local or read-only, with relatively few requiring strict read/write (R/W) synchronization. This suggests that optimizing for global SC might not be the best approach for modern multiprocessors.

## Does an Instagram-Like System Need SC?

Implementing Instagram (or any large-scale social media platform) on a multi-core processor raises the question: is Sequential Consistency (SC) necessary? The answer depends on which parts of the system require strict memory ordering.

-   For basic content delivery (loading posts, images, likes), SC is unnecessary because these operations don't require strict synchronization---eventual consistency is fine.

-   For counters (like counts, view counts), SC isn't required either since approximate values are acceptable, and techniques like relaxed consistency with periodic synchronization work well.

-   For critical sections like comments and replies, SC becomes more important. If two users reply to a comment at the same time, ensuring correct order matters, or discussions could become garbled.

##  Finding the Right Balance: SC vs. Scalability

A single point of consistency in the system (such as a single-threaded bottleneck) is a bad idea because it creates a failure-prone and slow system. Instead, modern architectures rely on distributed databases and eventual consistency, selectively enforcing strong consistency where it truly matters (transactional updates, authentication). For programmers, this is a trade-off between consistency and scalability---strict SC ensures correctness but hurts performance, while weaker models improve capacity at the cost of occasional inconsistencies. 

##  Are They Being Selective With Their Benchmarks?

It's fair to question whether the benchmarks used in the paper accurately represent real-world workloads. The authors focus on PARSEC, SPLASH-2, and Apache benchmarks, which are widely used in academic research, but they don't explicitly show how much data sharing actually occurs in these workloads. A moderation graph showing the percentage of shared vs. unshared data accesses would help clarify whether SC optimizations are truly impactful in common cases.

## Are These Workloads Reflective of Modern Applications?

While these benchmarks were relevant at the time, they don't necessarily represent today's software landscape. One glaring omission is AI/ML workloads, which heavily rely on parallelism and could benefit from or break under strict SC enforcement. Given that this paper was published before the AI/ML boom, it's understandable that such benchmarks weren't included, but it still highlights a broader issue with academic evaluations---they often miss fast-moving trends in real-world computing.

## Benchmark Selection Matters in Paper Acceptance

A key issue with research papers is how benchmarks influence acceptance. If reviewers believe the authors chose benchmarks that favor their results, they might reject the paper for not testing "software that actually matters." Adding more diverse workloads, especially those involving data-heavy and modern parallel computing applications, would make the findings more generalizable and harder to dismiss.

## Sources:

-   End-to-end sequential consistency: http://web.cs.ucla.edu/~todd/research/isca12.pdf

-   OSTEP Textbook Remzi Arpaci-Dusseau 

-   Computer Organization and Design RISC-V Edition The Hardware Software Interface 2nd Edition - December 11, 2020 Authors: David A. Patterson, John L. Hennessy 

-   Computer Architecture, Sixth Edition: A Quantitative Approach December 2017 Authors: John L. Hennessy, David A. Patterson

## Generative AI 

-   Link to specific Tools: <https://chatgpt.com/> <https://www.deepseek.com/>  <https://claude.ai>

-   This tool was used to help generate ideas for the outline, provide explanations of keywords, and offer feedback on prose.

-   Claude appears to have a tiny context window that is unusable for long conversations. However, it apparently has a much larger context window than chatgpt which means that chatgpt has been truncating content without informing users. (<https://prompt.16x.engineer/blog/claude-sonnet-gpt4-context-window-token-limit>) 

-   Deepseek is frequently down due to poor cloud service and is also biased

-   ChatGPT has by far the best value proposition because of its user interface. 

-   Generative AI tools are excellent tools for brainstorming, offering feedback, and providing explanations. These tools should not be trusted for accuracy. Any specific detail mentioned must be externally validated.

-   Concrete example: changed "Has this been implemented anywhere (in actual hardware)

-   Published in 2012, could not find anything about it

-   Industry balks at research that fundamentally changes core architecture; might not be enough incentive to update architecture

-   Another guess: touches every part of the stack: special compiler, hardware, language, etc. 

-   Takes a long time to adopt; either all or nothing with adoption

-   " to "This approach has not been implemented in actual hardware. The paper was published in 2012, and there are no known commercial processors that have adopted this exact SC enforcement method. One major reason is that industry is slow to adopt changes that fundamentally alter core architecture. Implementing end-to-end SC enforcement requires modifications to hardware, compilers, operating systems, and programming models, making it a massive undertaking with uncertain incentives. Given that weak memory models already work well for performance, most companies don't see a strong reason to switch."

-   Information given could be misleading. For example, the LLM claimed and the strength of the paper was "Strong Experimental Validation - Uses widely recognized benchmarks to demonstrate real-world applicability." However, in the discussion, it was pointed out that the authors seemed to cherry pick their benchmarks.
