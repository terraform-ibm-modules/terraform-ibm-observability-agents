#!/bin/bash

set -e

daemonset=$1
namespace=$2

kubectl rollout status ds "${daemonset}" -n "${namespace}" --timeout 30m
