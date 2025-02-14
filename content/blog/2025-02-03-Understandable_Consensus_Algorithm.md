+++
title = "In Search of an Understandable Consensus Algorithm"
[extra]
bio = """
[Benjamin Knutson] is currently pursuing a B.S. in Electrical and Computer engineering, spends most of his time playing games, studying languages, and rushing to finish his homework.

[Rabecka Moffit] is an electrical engineering student pursuing a M.Eng. and a B.S at Oregon State University who enjoys gravel biking, surfing, and baking. 

[Nanda Velugoti] CS PhD student and their research interest is in Systems (Memory Systems, Operating Systems, etc) and is currently working on memory aware efficient power management scheme and PIM offloading.
"""
[[extra.authors]]
name = "Benjamin Knutson (leader)"
[[extra.authors]]
name = "Rabecka Moffit (blogger)"
[[extra.authors]]
name = "Nanda Velugoti (scribe)"
[[extra.authors]]
name = "Eugene Cohen"
[[extra.authors]]
name = "David Luo"

+++

## Background
Raft is a consensus algorithm that was created by two researchers at Stanford University in order to create a more understandable algorithm than Paxos. These algorithms were created for separate servers that work together to form a coherent group. The benefit of this working model is that the group can survive the death of some of the separate servers. The two researchers attempted to learn Paxos for over a year but were ultimately unsuccessful. The researchers decided that a new consensus algorithm needed to be designed with understandability at the forefront. 

In order to create a more understandable consensus algorithm the authors focused on decomposition of the solutions into three parts: leader election, log replication, and safety mechanisms. If the solutions could be broken down into smaller pieces, this would create more manageable pieces for understanding and using Raft. Another technique they used to increase the understandability was reducing the state spaces to simplify behavior and decrease nondeterminism. Unlike Paxos, which allows entries in the log to be entered in different ways, Raft ensures all logs match the leader's log, avoiding inconsistencies and this stems from having a leader, replicating logs to all systems, and the leader enforcing a log order.

## Main Contributions
The researchers contributed a new consensus algorithm that is open source.

## Results
The results of this paper showed that students scored higher test scores for Raft when given lectures about Raft and Paxos with the order of the lectures distributed evenly across the test group. 33 students out of 43 scored higher on the Raft test than on the Paxos test. The other result that was discussed in the paper was that the performance of Raft is comparable to Paxos.

## Impacts
The new consensus algorithm, Raft, was quickly and widely adopted which is in stark contrast to Paxos. Paxos was created in the late 1970s by Leslie Lamport but even though Lamport published Paxos paper, there was no widespread adoption. So he later published a “Paxos made simple” paper to make it more adaptable because people could not understand or use Paxos. This is why Raft is seen as an important alternative to Paxos. People were using Raft within weeks of this paper being published.


## Strength and Weaknesses
This paper highlighted the understandability of a consensus algorithm and the paper was written with seemingly similar goals in mind. This paper was by far the easiest to read of any we have looked at so far in class so that is a strength that not many technical papers have. The downside of this is that they seemed to have lost some technical detail that would have strengthened their claims of superiority. There was no test done to actually compare the functionality of Paxos to Raft and yet they claim that the performance is similar. This seems slightly suspicious especially after the authors self-reported that they couldn't really use Paxos. I also would like to see a larger sample size than 43 since this is a small sample size to get statistically significant data from. A weakness of Raft itself is that using one server as a leader could create a bottleneck within high-traffic systems.
