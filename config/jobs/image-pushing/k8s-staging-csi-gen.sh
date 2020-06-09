#!/usr/bin/env bash
# Copyright 2020 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit

readonly OUTPUT="$(dirname $0)/k8s-staging-csi.yaml"
readonly REPOS=(
    csi-driver-host-path
    csi-driver-iscsi
    csi-driver-nfs
    csi-driver-smb
    csi-proxy
    csi-test
    external-attacher
    external-health-monitor
    external-provisioner
    external-resizer
    external-snapshotter
    livenessprobe
    node-driver-registrar
)

cat >"${OUTPUT}" <<EOF
# Automatically generated by k8s-staging-csi-gen.sh.

postsubmits:
EOF

for repo in "${REPOS[@]}"; do
    cat >>"${OUTPUT}" <<EOF
  kubernetes-csi/${repo}:
    - name: post-${repo}-push-images
      cluster: k8s-infra-prow-build-trusted
      annotations:
        testgrid-dashboards: sig-storage-image-build
      decorate: true
      branches:
        # For publishing canary images.
        - ^master$
        - ^release-
        # For publishing tagged images. Those will only get built once, i.e.
        # existing images are not getting overwritten. A new tag must be set to
        # trigger another image build. Images are only built for tags that follow
        # the semver format (regex from https://semver.org/#is-there-a-suggested-regular-expression-regex-to-check-a-semver-string).
        - ^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-((?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\.(?:0|[1-9]\d*|\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\+([0-9a-zA-Z-]+(?:\.[0-9a-zA-Z-]+)*))?$
      spec:
        serviceAccountName: gcb-builder
        containers:
          - image: gcr.io/k8s-testimages/image-builder:v20200422-c760048
            command:
              - /run.sh
            args:
              # this is the project GCB will run in, which is the same as the GCR
              # images are pushed to.
              - --project=k8s-staging-csi
              # This is the same as above, but with -gcb appended.
              - --scratch-bucket=gs://k8s-staging-csi-gcb
              - --env-passthrough=PULL_BASE_REF
              - .
EOF
done
