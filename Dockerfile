FROM registry.access.redhat.com/ubi9/ubi:latest as base

# Grab build args from the environment
ARG GIT_HASH
ENV GIT_HASH=$GIT_HASH

ARG BUILD_DATE
ENV BUILD_DATE=$BUILD_DATE

WORKDIR /build
COPY . .

# Install go so we can get bom
RUN dnf update -y && dnf install -y rpm-build && dnf builddep -y rpm/evergreen-container-base.spec
ENV GOPATH=/app/bom

# Install bom
RUN go install sigs.k8s.io/bom/cmd/bom@latest

# Have bom make an SBOM of itself
WORKDIR /app/bom
RUN export BOM_VERSION=$(bin/bom version --json | jq .gitVersion | sed 's/\"//g') && \
    bin/bom generate \
    --format json \
    --name bom-${BOM_VERSION} \
    . | \
    gzip --best > bom-${BOM_VERSION}.spdx.json.gz

# Make an RPM of things we want out of this layer
RUN export BOM_VERSION=$(bin/bom version --json | jq .gitVersion | sed 's/\"//g') && \
    rpmbuild -ba \
    --define "_git_hash ${GIT_HASH}" \
    --define "_topdir /build" \
    --define "_bom_version ${BOM_VERSION}" \
    --define "_build_date ${BUILD_DATE}" \
    /build/rpm/evergreen-container-base.spec



# Now build the layer where we'll actually build things
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest as build


# (Not sure if these need repeated here?)
ARG GIT_HASH
ENV GIT_HASH=$GIT_HASH

ARG BUILD_DATE
ENV BUILD_DATE=$BUILD_DATE

WORKDIR /build

# Go get the RPM we just made
COPY --from=base /build/RPMS/x86_64/evergreen-container-base-${BUILD_DATE}-${GIT_HASH}.el9.x86_64.rpm .
RUN rpm -i evergreen-container-base-${BUILD_DATE}-${GIT_HASH}.el9.x86_64.rpm

#
# Install whatever is needed to build things!
#




#
# Then make a tiny runtime image that copies in the build artifacts
#

#FROM registry.access.redhat.com/ubi9/ubi-micro:latest as runtime


