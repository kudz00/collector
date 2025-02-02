#!/usr/bin/env bash
set -e

set -ux
ldconfig -v
cd /tmp/cmake-build
CMAKE_BUILD_TYPE="${CMAKE_BUILD_TYPE:-Release}"
ADDRESS_SANITIZER="${ADDRESS_SANITIZER:-false}"
COLLECTOR_APPEND_CID="${COLLECTOR_APPEND_CID:-false}"

if [ "$ADDRESS_SANITIZER" = "true" ]; then
    # Needed for address sanitizer to work. See https://github.com/grpc/grpc/issues/22238.
    # When Collector is built with address sanitizer it sets GRPC_ASAN_ENABLED, which changes a struct in the grpc library.
    # If grpc is compiled without that flag and is then linked with Collector the struct will have
    # two different definitions and Collector will crash when trying to connect to a grpc server.
    while read -r file; do
        sed -i 's|#include <grpc/impl/codegen/port_platform.h>|#include <grpc/impl/codegen/port_platform.h>\n#ifdef GRPC_ASAN_ENABLED\n#  undef GRPC_ASAN_ENABLED\n#endif|' "$file"
    done < <(grep -rl port_platform.h /src/generated --include=*.h)
fi

extra_flags=(
    -DCMAKE_BUILD_TYPE="$CMAKE_BUILD_TYPE"
    -DADDRESS_SANITIZER="$ADDRESS_SANITIZER"
    -DCOLLECTOR_APPEND_CID="$COLLECTOR_APPEND_CID"
)

cmake "${extra_flags[@]}" /src
make -j "${NPROCS:-2}" all
if [ "$CMAKE_BUILD_TYPE" = "Release" ]; then
    echo "Strip unneeded"
    strip --strip-unneeded \
        ./collector \
        ./EXCLUDE_FROM_DEFAULT_BUILD/libsinsp/libsinsp-wrapper.so
fi
cp -r /THIRD_PARTY_NOTICES .
