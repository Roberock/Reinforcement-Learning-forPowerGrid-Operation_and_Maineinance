# A reinforcement learning framework for optimal operation and maintenance of power grids


## Abstract: 
We develop a Reinforcement Learning framework for the optimal management of the operation and maintenance of power grids equipped with prognostics and health management capabilities. Reinforcement learning
exploits the information about the health state of the grid components. Optimal actions are identified maximizing the expected profit, considering the aleatory uncertainties in the environment. To extend the applicability of the proposed approach to realistic problems with large and continuous state spaces, we use Artificial
Neural Networks (ANN) tools to replace the tabular representation of the state-action value function. The nontabular Reinforcement Learning algorithm adopting an ANN ensemble is designed and tested on the scaled-down
power grid case study, which includes renewable energy sources, controllable generators, maintenance delays
and prognostics and health management devices. The method strengths and weaknesses are identified by
comparison to the reference Bellman’s optimally. Results show good approximation capability of Q-learning with
ANN, and that the proposed framework outperforms expert-based solutions to grid operation and maintenance
management.

See the following article for more details:

``` bibtex
@article{ROCCHETTA2019291, 
title = "A reinforcement learning framework for optimal operation and maintenance of power grids",
journal = "Applied Energy", volume = "241", pages = "291 - 301", year = "2019",
issn = "0306-2619", 
doi = "https://doi.org/10.1016/j.apenergy.2019.03.027", 
author = "R. Rocchetta and L. Bellani and M. Compare and E. Zio and E. Patelli", }
```


```
.
├── MDP                         # Markov-Decision-Process folder 
│   ├── OPF.m                   # Optimal power flow solver (DC-OPF) considering virtual generators to compute the Energy not supplied
│   ├── Data4_BusNet.m          # THE DATA FOR THE Scaled-Down 4 nodes power grid with renewables
│   ├── Q_BellmanOptimality.m   # Computes the Bellman's optimality for the grid use case (reference solution)
 
├── Tabular                     #  Tabluar Reinforcement Learning methods:  SARSA and Q-learning method applied to the power grid usecaase
│   ├── ...                   
 

├── NonTabular                  # Non-Tabular RL methods: NeuralNetworks applied a Qtable regressors and DeepQ-learning method applied to the power grid usecaase
│   ├── ...           
```
