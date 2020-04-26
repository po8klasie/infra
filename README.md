# WarsawLO Infra

Infra for WarsawLO.

Goals:
* minimum cost
* minimum maintenance
* survive big spikes in traffic
* automated deploys, at least to the test instance
* currently stateless, but has to be able to support statefulness (only in db) in the future

Non goals:
* automated bootstrapping: initial setup won't happen that often

## Architecture Overview

![Architecture Diagram][WarsawLO Architecture.png]