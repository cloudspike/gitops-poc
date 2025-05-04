# Flux

Deploys four controllers by default:
* source-controller
* kustomize-controller
* helm-controller
* notification-controller

By default Flux watches all namespaces for its Kustomization objects to act upon.

## Bootstrap

`flux` command line is used to deploy CRDs and initial config to cluster.

`flux bootstrap` by default pushes commits to repo. Ideally I would prefer if it would
generate the files locally so that I can push the commit. Maybe there is a way to avoid
git push?

## Progressive deploy to staging & production

Example: https://github.com/fluxcd/flux2-kustomize-helm-example

The idea of progression is that either container image or helm relase is released first
with a pre-release tag, then a final tag. So for HelmRelease CRD:

```
spec:
  chart:
    spec:
      version: ">=1.0.0-alpha"
```

The version above will match not only alpha but other suffixes as well while version of
`version: ">=1.0.0"` would only match releases without suffix. That is how Flux
imagines progression from staging to production - leaving it to versioning.

## Multitenancy

There is a concept of a "tenant" under development in Flux:
https://github.com/fluxcd/flux2-multi-tenancy

## Optional image update automation

It is possible to deploy a controller which checks registry for
image tags and updates the image tag reference in git.

Doc: https://fluxcd.io/flux/guides/image-update/

Bootstrap command would need to be amended to include:

```
--components-extra=image-reflector-controller,image-automation-controller \
--read-write-key \
```

This means that an in-cluster controller will write to source repo,
which might feel iffy for some.

Github deploy key will need to be `"read_only": false` as well.


