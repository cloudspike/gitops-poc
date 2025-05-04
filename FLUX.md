# Flux

Deploys four controllers by default:
* source-controller
* kustomize-controller
* helm-controller
* notification-controller

`flux` command line is used to deploy CRDs to cluster.

By default Flux watches all namespaces for its Kustomization objects to act upon.

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


