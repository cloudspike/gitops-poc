# Exploration of GitOps

The idea of this repository is to test following GitOps approach to cluster bootstrap:

We provision a minimalistic `kind` cluster where we bootstrap either Flux or ArgoCD.

All other configuration after GitOps is working is done though the chosen tool.

When possible we prefer to vendor manifests instead of using opaque helm charts.
For that purpose we maintain scripts which download upstream manifests into this repo.
