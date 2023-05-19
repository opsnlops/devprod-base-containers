FROM registry.access.redhat.com/ubi9/ubi:latest as build


# Grab build args from the command line
ARG GIT_HASH

WORKDIR /build
COPY . .

# Install go so we can get bom
RUN dnf update -y && dnf install -y rpm-build && dnf builddep -y rpm/evergreen-container-base.spec

ENV GOPATH=/app/bom

RUN go install sigs.k8s.io/bom/cmd/bom@latest

# Have bom make an SBOM of itself
WORKDIR /app/bom
RUN export BOM_VERSION=$(bin/bom version --json | jq .gitVersion | sed 's/\"//g') && \
    bin/bom generate \
    --format json \
    --name bom-${BOM_VERSION} \
    . | \
    gzip --best > bom-${BOM_VERSION}.spdx.json.gz


RUN export BOM_VERSION=$(bin/bom version --json | jq .gitVersion | sed 's/\"//g') && \
    rpmbuild -ba \
    --define "_git_hash ${DRONE_COMMIT_SHA}" \
    --define "_topdir /build" \
    --define "_bom_version ${BOM_VERSION}" \
    rpm/evergreen-container-base.spec \
