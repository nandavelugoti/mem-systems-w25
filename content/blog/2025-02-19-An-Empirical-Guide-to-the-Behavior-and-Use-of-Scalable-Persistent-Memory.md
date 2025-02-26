+++
title = "An Empirical Guide to the Behavior and Use of Scalable Persistent Memory"
[extra]
bio = """
  [Noah Bean] is an undergraduate student studying Electrical and Computer Engineering at Oregon State University.
"""
[[extra.authors]]
name = "Shuxian Qin (Blogger) "
[[extra.authors]]
name = "Shuyi Zheng (Scribe) "
[[extra.authors]]
name = "Noah Bean (Leader) "
+++

## Introduction

This blog discusses "An Empirical Guide to the Behavior and Use of Scalable Persistent Memory." This work stands out as the first real-world performance benchmark of Intel’s Optane DIMMs, a groundbreaking technology that brings scalable, byte-addressable persistent memory to the computing landscape. Designed to bridge the gap between the fast but volatile DRAM and the slower, non-volatile SSDs, Optane DIMMs promised a new era of memory systems after nearly a decade of anticipation. The paper dives into how these devices actually perform, revealing surprises that upend assumptions from years of research based on emulated setups like DRAM stand-ins. Far from being just "slower DRAM," Optane exhibits unique quirks that demand fresh thinking. Its authors set out not only to measure Optane’s behavior but also to deliver practical guidelines for software developers to optimize their code for this novel hardware. This blog unpacks their findings, shedding light on a technology that’s as complex as it is promising.

## Background and Context

Persistent memory represents a transformative leap in the memory hierarchy, blending traits that set it apart from traditional technologies. Unlike DRAM, which loses its contents when power is cut, persistent memory is non-volatile, retaining data even after shutdowns. It’s denser too, packing more storage capacity into less space at a lower cost per gigabyte than DRAM. This makes it a versatile player, sitting between DRAM’s speed and SSDs’ persistence. Its byte-addressable nature—allowing direct access to individual memory locations—unlocks a range of use cases: speeding up database transaction logging and in-memory databases, providing fast persistent caching for high-performance computing (HPC), boosting memory-intensive virtualization in cloud setups, and accelerating storage as a cache or tiered layer.

For over a decade, researchers have been gearing up for persistent memory’s arrival, but without real hardware like Intel’s Optane DIMMs, they relied on emulations—often using DRAM tweaked to mimic non-volatile memory (NVM). These setups, sometimes paired with artificial delays or NUMA effects, fueled speculation about how NVM would behave. However, powered by 3D XPoint technology (a joint Intel-Micron innovation), Optane does not behave as expected. Unlike DRAM’s straightforward capacitor-based design, 3D XPoint introduces “second-order changes”—subtle, cascading effects in latency, bandwidth, and concurrency that add a new layer of complexity. Where DRAM emulation suggested predictable performance, Optane’s real-world behavior defies those models, revealing quirks that prior speculations couldn’t anticipate. This shift challenges the research community to rethink how software interacts with memory, setting the stage for the detailed benchmarks and insights this paper delivers.

## Keywords

- **Persistent Memory**: A type of memory that retains data even after power is lost, combining non-volatility with high density and often byte-addressable access, bridging the gap between DRAM and SSDs.
- **Non-Volatile Memory (NVM)**: Memory that preserves data without power, unlike volatile DRAM; includes technologies like flash and persistent memory like Optane.
- **Optane DIMM**: Intel’s scalable persistent memory module, built on 3D XPoint tech, offering byte-addressable, non-volatile storage in DIMM form for consumer and data center use.
- **3D XPoint**: A non-volatile memory technology developed by Intel and Micron, using a crosspoint structure with resistive switching (not transistors) for high speed and endurance.
- **App Direct Mode**: An Optane operating mode exposing it as a separate persistent memory device, managed by software for direct access, without DRAM caching.
- **Memory Mode**: An Optane mode using it as volatile main memory with DRAM as a transparent cache, expanding capacity without persistence.
- **Asynchronous DRAM Refresh (ADR)**: Intel’s feature ensuring data in the memory controller’s write queues (WPQs) is flushed to persistent media during power loss, within a short hold-up time.
- **Write Amplification**: The increase in data written to memory beyond what the application requests, often due to block-sized updates (e.g., Optane’s 256B granularity).
- **Non-Temporal Store (ntstore)**: A CPU instruction bypassing the cache to write directly to memory, useful for large sequential writes to avoid cache pollution.
- **iMC (Integrated Memory Controller)**: The CPU component managing memory access, including read/write queues (RPQs/WPQs), critical for Optane’s ADR domain.
- **Wear Leveling**: A technique to distribute writes evenly across memory cells, preventing overuse and extending lifespan, potentially causing Optane’s tail latency spikes.
- **CXL (Compute Express Link)**: An emerging interconnect standard for coherent memory access, supporting persistent and disaggregated memory, seen as an Optane alternative.
- **1T1C (One Transistor, One Capacitor)**: The basic cell design of DRAM, using a transistor-capacitor pair for each bit, contrasting with 3D XPoint’s resistive approach.

## Summary of the Paper

### 1. Introduction
The paper discusses the decade-long wait for scalable non-volatile memory (NVM), a technology researchers have speculated about since the early 2000s. Intel’s Optane DIMMs finally arrived in 2019, offering a real-world testbed to challenge those expectations. The authors set out to measure how this persistent memory performs, aiming to replace guesswork from emulated setups with data.

### 2. Background and Methodology
This section discusses how optane works. It plugs into Intel’s Cascade Lake processors (24 cores, dual-socket, 3 TB total Optane across 2 sockets with 6 channels each). Unlike DRAM, Optane uses 256B blocks for internal writes, managed by an on-DIMM controller (XPController) and the CPU’s integrated memory controller (iMC), which handles write pending queues (WPQs). The Asynchronous DRAM Refresh (ADR) feature ensures data in WPQs persists during power loss. The study focuses on App Direct mode—where Optane acts as a standalone persistent device—running on Fedora 27 with a custom kernel, testing 384 GB DRAM alongside 256 GB Optane DIMMs per channel.

### 3. Performance Characterization
Read latency clocks in at 2x-3x higher than DRAM, with random reads hit harder than sequential ones due to the 256B XPBuffer’s limits. Tail latency spikes—up to 50 µs, 100x the norm—pop up unpredictably, likely from wear leveling. Bandwidth tells a split story: reads scale well with threads (up to 16), but writes plateau early (around 4-12 threads) and dip with more concurrency, far less scalable than DRAM’s steady climb. Small random writes tank performance, while sequential ones hold up better.

### 4. Comparison to Emulation
Past NVM studies used DRAM with delays or NUMA tricks, predicting Optane as “slower DRAM.” Real tests flip that script. In RocksDB, emulation favored fine-grained persistence (moving the memtable to NVM), but on Optane, the FLEX approach (sequential write-ahead logging) wins by 10%, thanks to its dislike for small random writes. Emulated guesses missed Optane’s nuanced behavior.

### 5. Best Practices for Optane DIMMs
The paper distills four guidelines from microbenchmarks: avoid small random writes under 256B (they amplify due to block size), use non-temporal stores (ntstores) for large sequential writes (bypassing cache boosts bandwidth), limit threads hitting one DIMM (more than 4-12 thrash the XPBuffer and iMC), and steer clear of NUMA accesses (remote hits crater performance, up to 30x worse than DRAM’s 3.3x). 

### 6. Discussion
Looking ahead, the authors muse on how these tips might evolve. Extended ADR (eADR), including caches in the persistent domain, could nix ntstore needs. CXL might shift persistent memory paradigms, while bigger buffers or smaller blocks (unlike 256B) could tweak trade-offs—though power limits complicate that. The guidelines offer a roadmap for future NVM, even if Optane’s specifics change.

### 7. Related Work
Before Optane, NVM research relied on emulation. These shaped file systems, transactional models, and data structures, but lacked real hardware validation. This paper marks a pivot to tangible benchmarks.

### 8. Conclusion
Optane DIMMs emerge slower (2x-3x DRAM latency) and more complex than expected, with thread scaling and write granularity tripping up performance. Coders bear the burden of optimization. As the first real benchmark of persistent memory, this study swaps speculation for data, spotlighting Optane’s promise and pitfalls.

## Important Results and What They Mean

**Emulation Errors**: For years, researchers emulated non-volatile memory (NVM) with DRAM, tweaking it to guess how Optane might behave. Real tests cleared up this assumption. 

**Latency/Bandwidth**: Read latency hits 2x-3x higher than DRAM, with random reads suffering more than sequential ones due to internal buffering limits. Write bandwidth lags too, far below DRAM’s, and scalability takes a hit: while DRAM’s bandwidth climbs steadily with threads, Optane peaks at 4-12 threads (reads at 16, writes at 4) then drops off—a stark contrast to DRAM’s monotonic rise.

**256B Granularity**: Small random writes (under 256B) amplify—updating one byte means rewriting the whole block, slashing efficiency and bandwidth. Sequential writes, though, shine, aligning with the block size to minimize overhead. This split explains why random access patterns tank performance while sequential ones improve performance.

**Tail Latency**: Reliability is reduced by rare tail latency spikes—up to 50 µs, 100x the typical latency. These outliers, likely from wear leveling or internal remapping, are sparse (0.006% of accesses) but cause serious problems. For systems needing predictability, like databases or real-time apps, this is a red flag.

## Strengths and Weaknesses of the Paper

### Strengths

**First Real Optane Benchmark**: This paper stands out as the first benchmark of Intel’s Optane DIMMs with actual hardware.

**Practical Guidelines with Case Studies**: Beyond measurements, it offers actionable advice—avoid small writes, limit threads, use ntstores—backed by real-world tweaks. 

### Weaknesses

**Limited Testing Scope**: The paper’s focus narrows to RocksDB and NOVA, with testing confined to App Direct mode. This leaves Memory Mode and broader applications unexplored, raising questions about how well the findings generalize across diverse workloads or setups.

**No Cost-Benefit Analysis or NVM Comparisons**: It skips the economics—Optane’s cost “dramatically increases” compared to DRAM or SSDs, but there’s no breakdown of trade-offs or benefits to justify it. Nor does it stack Optane against other NVM technologies, leaving a gap in context.

## Class Discussion

**Capacitors in 3D XPoint**: The 3D XPoint explainer video sparked curiosity. Unlike DRAM’s 1T1C (one transistor, one capacitor) simplicity, 3D XPoint’s crosspoint structure ditches transistors for resistive switching, with capacitors likely aiding dense packing and fast bit access. 

**256B Block Size**: Why 256B? Is it baked into Optane’s DNA or a deliberate pick? Eugene wondered if smaller blocks (say, 64B) could ease small-write woes—random writes under 256B tank performance due to whole-block updates. Kyle Hale guessed 256B strikes a “good medium ground,” balancing efficiency and complexity. Smaller blocks might cut amplification but could spike power demands or shrink density, a trade-off Optane’s designers might have dodged. 

**NUMA Puzzle**: Optane’s NUMA penalty—up to 30x bandwidth drop vs. DRAM’s 3.3x. Class eyed iMC contention: mixed read-write loads (like 3:1 ratios) clog short queues, worse with remote nodes. Eugene suggested it’s less iMC and more NVDIMM thrashing, but DRAM handles NUMA better.

**Thread Scaling**: Bandwidth peaking at 4-12 threads then dropped. Eugene blamed XPBuffer thrashing—multiple threads trash its 16KB write-merging space. Class added iMC queues: slow Optane drainage blocks them, slashing throughput. Is it buffer size, queue depth, or both? How do we keep threads from tripping over each other?

**Interconnect Efficiency**: Optane’s interconnect got scrutiny. How does it handle mixed read-write access? Class asked about gigabytes-per-second graphs (assuming bandwidth), wondering if it copes under chaos.

**Commercial Fate**: Intel’s 2022 Optane exit, after a $7B loss, hit hard. This was refered to as “swept under the rug.” Supply chain difficulty and high costs tanked it. Micron got out of persistent memory, but tinkering with persistent memory persists. CXL’s rising for persistent and disaggregated setups.

**eADR Shift**: eADR was brought up — cache-inclusive ADR from Intel’s 3rd-gen Xeons. It simplifies coding (no ntstores or flushes) and boosts bandwidth by keeping caches persistent. Class saw it easing Optane’s quirks.

**Security Risks**: DIMM theft was mentioned. If someone takes an Optane DIMM, data’s readable. How big of a problem is this? For databases or HPC, it’s a dealbreaker; consumer use, maybe less so. Why no mitigation discussion in the paper?

**Hybrid Potential**: The class pitched DRAM (1T1C speed) plus Optane (persistence). Class liked the idea: DRAM for fast random access, Optane for big persistent stores.

## Sources:

-   An Empirical Guide to the Behavior and Use of Scalable Persistent Memory: [http://web.cs.ucla.edu/~todd/research/isca12.pdf](https://www.usenix.org/conference/fast20/presentation/yang)

-   OSTEP Textbook Remzi Arpaci-Dusseau 

-   Computer Organization and Design RISC-V Edition The Hardware Software Interface 2nd Edition - December 11, 2020 Authors: David A. Patterson, John L. Hennessy 

-   Computer Architecture, Sixth Edition: A Quantitative Approach December 2017 Authors: John L. Hennessy, David A. Patterson

## Generative AI 

-   Link to specific Tools: <https://chatgpt.com/> <https://www.deepseek.com/> <https://claude.ai> <https://gemini.google.com/app>

| **Metric**            | **ChatGPT 4o (GPT-4o)** | **DeepSeek R1** | **Gemini 2.0 Flash** | **Claude 3.7 Sonnet** |
|-----------------------|-------------------------|-----------------|----------------------|-----------------------|
| **MMLU Accuracy**     | 88.7%                  | 85%             | 80%                  | 88%                   |
| **TruthfulQA Accuracy** | 65%                  | 60%             | 55%                  | 62%                   |
| **HellaSwag Accuracy** | 96%                   | 94%             | 90%                  | 95%                   |
| **GSM8K Accuracy**    | 95%                   | 92%             | 85%                  | 94%                   |
| **BBH Accuracy**      | 85%                   | 75%             | 70%                  | 85%                   |
| **HumanEval Pass Rate** | 85%                  | 80%             | 75%                  | 84%                   |

- ### Key Observations
- **ChatGPT 4o** consistently performs at or near the top across all metrics, achieving the highest average score of 85.78%. It stands out in knowledge (MMLU), truthfulness (TruthfulQA), commonsense reasoning (HellaSwag), mathematical reasoning (GSM8K), and code generation (HumanEval), while tying for the lead in advanced reasoning (BBH). This broad excellence makes it the most well-rounded model among those analyzed.
- **Claude 3.7 Sonnet** is a very close second with an average score of 84.67%. It matches ChatGPT 4o in advanced reasoning (BBH) and performs strongly in most areas, though it falls slightly behind in truthfulness (TruthfulQA) and code generation (HumanEval). Its near parity with ChatGPT 4o highlights its competitive edge.
- **DeepSeek R1** secures a solid third place with an average score of 81.00%. It delivers competitive results across most metrics but lags in advanced reasoning (BBH) and truthfulness (TruthfulQA).
- **Gemini 2.0 Flash** trails with an average score of 75.83%, likely due to its design as a faster, smaller model optimized for efficiency.
  
-   This tool was used to help generate ideas for the outline, provide explanations of keywords, and offer feedback on specific prose.

-   Generative AI tools are excellent tools for brainstorming, offering feedback, and providing explanations. These tools should not be trusted for accuracy. Any specific detail mentioned must be externally validated.

-   Concrete example: changed "A memory type that holds data after power loss. Has high density and sits between DRAM and SSD." to "A type of memory that retains data even after power is lost, combining non-volatility with high density and often byte-addressable access, bridging the gap between DRAM and SSDs."

-   Information given could be misleading. For example, the LLM claimed that a weakness of the paper was that "Intel axed Optane in 2022 after a $7B loss, signaling a “lack of profit” that the paper doesn’t address. This omission sidesteps a critical real-world angle—why a promising tech flopped commercially—limiting its forward-looking relevance." However, this paper came out before Intel "axed" optane in 2022 so this weakness should not be fairly considered. 
