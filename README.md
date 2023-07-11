Further documentation available [here](https://docs.google.com/document/d/17NFwGvn4vMEXZV9Qmg30BqAcKrdxBYCOB4pFdkkwIIo/edit#)

# Using this template

This template repository should be used as the base for new workflow repositories which will use the new Docker packaging scheme.

# CWL Workflow Development

## Pre-requisites

- Docker
- [just](https://github.com/casey/just)
- `jq` (recommended)

`just init` will install the correct version of `cwltool`, `jinja-cli`, and `pre-commit`, be sure to have a python3.8+ virtual environment active.

`just build-all` will build and validate all workflows in the repo.

## Just

The `just` utility is a command runner replacement for `make`.

It has various improvements over `make` including the ability to list available command with `just -l`:

### Root Justfile

```
Available recipes:
    build WORKFLOW # Builds individual workflow
    build-all      # Builds all docker images for each directory with a justfile
    init
    pack WORKFLOW  # Builds Docker for WORKFLOW and prints packed JSON
```

The root `justfile` provides recipes for Dockerizing workflows locally, while workflow-level `justfiles` provide recipes for building the workflow.

### Workflow Justfile

The workflow-level `justfile` requires the `ENTRY_CWL` path be updated.

```
# justfile
ENTRY_CWL := "workflow.cwl"
```

Certain recipes check if the `ENTRY_CWL` file exists, and will show an error message if not.

```
Available recipes:
    get-dockers          # Formats and prints all Dockers used in workflow
    get-dockers-template # Prints all dockerPull declarations in unformatted workflow
    inputs               # Print template input file for workflow
    pack                 # Pack and apply Jinja templating. Creates cwl.json file
    validate             # Validates CWL workflow
```

Some important commands for workflow development:

`just validate` will run cwltool's validation and show any errors in the CWL.

`just inputs` will output a template input file for the workflow.

`just get-dockers-template` will pack the workflow to JSON and print all unique dockerPull declarations.

This command is useful for building the `dockers.json` file or finding un-templated image strings.

`just get-dockers` will pack the workflow to JSON and apply the Docker formatting.

No template strings should remain after formatting.

## dockerPull Jinja Templates

For CommandLineTool workflows utilizing `dockerPull`, the docker image should be specified in CWL as a jinja-compatible template string.

`dockerPull: "{{ docker_repository }}/image_name:{{ image_name }}"`

__NOTICE__: Double quotes required

Within each workflow's `justfile` is the `just pack` command which:

1. Packs the CWL workflow into a temporary JSON file
2. Uses `jinja-cli` and the `dockers.json` file to replace each template string
3. Saves the result to `cwl.json`

------

### `dockers.json`

```json
{
        "docker_repository": "docker.osdc.io/ncigdc",
        "image_name": "abcdef"
}
```

This JSON file combined with the example string above will result in a final string:

`dockerPull: "docker.osdc.io/ncigdc/image_name:abcdef`

in the packed cwl.json file.

------

While this prevents the CWL from being used directly, it enables easy updating of multiple Docker images for GPAS, and allows external users to supply their own images/tags.

## Repository Structure

### Top-level

The top level of the workflow repository should contain a `justfile`, `build.sh` script, and a `.gitlab-ci.yml` config.

Small CWL scripts not specific to any workflow should be stored in a top-level `tools` directory. These can include general shell commands and `CommandLine` workflows to call bioinformatics tools.

__NOTICE__: This `tools` directory will be copied to the root of the Docker image. Relative path references to CWL in tools will remain valid in both the repo filesystem and docker image filesystem.

Eventually these tooling CWL scripts will be stored in a common library.

The `build.sh` script is used to automatically build and publish images in a CI environment.

The `justfile` contains commands to locally build workflow images, run `just -l` for a full list of commands.

Individual workflow CWL scripts should be stored within top-level directories named after the workflow.

### Workflow Subdirectory

Each workflow directory should also contain the template justfile and Dockerfile.

The `ENTRY_CWL` should be updated with the path to the main workflow cwl script, relative to the workflow directory.

This CWL script will be used as the argument to the `cwltool --pack` command, but can be overwritten using `make pack ENTRY_CWL=...`

The CWL scripts comprising a workflow can be stored under any manner of directory structure.

Ideally any CWL script referenced by another file is in the same directory or a subdirectory of the calling script. (Essentially do not traverse up a directory, only sideways and/or down).

This will enable moving an entire subdirectory, if needed, without needing to update any references contained within.

## Workflow Docker Image

The Docker image for a CWL workflow should be based on the `bio-alpine:cwltool3` image, which provides the bare minimum required to run the `cwltool --pack` command.

Each feature branch commit will be published to the internal `dev-containers.osdc.io`, still accessible via the `docker.osdc.io` proxy.

Upon merging to `main` or `master`, the image(s) will be published to the permanent `containers.osdc.io` and tagged with both the commit hash and a datetime-stamp.

Quay will be depreciated for new workflows and phased out for existing ones.
