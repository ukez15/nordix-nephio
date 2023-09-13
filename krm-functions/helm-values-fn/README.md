# helm-values-fn

## Overview

<!--mdtogo:Short-->

This function is a simple values.yaml generator.

<!--mdtogo-->

Application config is often captured in values.yaml, but it is difficult to edit
the contents of the values.yaml with KRM functions. This allows function inputs to
be used to generate values.yaml files, and those inputs can be more easily edited than
the raw values.yaml data values.

<!--mdtogo:Long-->

## Usage

To use this function, define a HelmValues resource for each values.yaml you want
to generate. It can be used declaratively or imperatively, but it does require
the HelmValues Kind; you cannot run it using a simple values.yaml for inputs.

When run, it will create or overwrite a values.yaml, and generate `data` field
entries for each of the listed values in the function config.

### FunctionConfig

```yaml
apiVersion: fn.kpt.dev/v1alpha1
kind: HelmValues
metadata:
  name: my-generator
helmValuesMetadata:
  name: my-helm-values
  labels:
    foo: bar
params:
  hostname: foo.example.com
  port: 8992
  scheme: https
  region: us-east1
data:
- type: literal
  key: hello
  value: there
- type: gotmpl
  key: dburl
  value: "{{.scheme}}://{{.hostname}}:{{.port}}/{{.region}}/db"
```

The function config above will generate the following values.yaml:

```yaml
kind: HelmValues
metadata:
  name: my-helm-values
   labels:
    foo: bar
data:
  dburl: https://foo.example.com:8992/us-east1/db
  hello: there
```

If `helmValuesMetadata.name` is not defined, the generated values.yaml will use the
name of the HelmValues resource.

<!--mdtogo-->

## Future Work

This function is very basic right now. Integration with CEL and implementation
of features found in the Kustomize Generator would be valuable.
