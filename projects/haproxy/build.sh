#!/bin/bash -eu
# Copyright 2020 Google Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
export ORIG_CFLAGS=${CFLAGS}
cd haproxy

# Fix some things in the Makefile where there are no options available
sed 's/LD = $(CC)/LD = ${CXX}/g' -i Makefile
sed 's/CC = gcc/#CC = gcc/g' -i Makefile
sed 's/CFLAGS = $(ARCH_FLAGS) $(CPU_CFLAGS) $(DEBUG_CFLAGS) $(SPEC_CFLAGS)/CFLAGS = $(ARCH_FLAGS) $(CPU_CFLAGS) $(DEBUG_CFLAGS) $(SPEC_CFLAGS) ${ORIG_CFLAGS}/g' -i Makefile
sed 's/LDFLAGS = $(ARCH_FLAGS) -g/LDFLAGS = $(ARCH_FLAGS) -g ${CXXFLAGS}/g' -i Makefile
make TARGET=generic

# Make a copy of the main file since it has many global functions we need to declare
# We dont want the main function but we need the rest of the stuff in haproxy.c
cd /src/haproxy
sed 's/int main(int argc/int main2(int argc/g' -i ./src/haproxy.c
sed 's/dladdr(main,/dladdr(main2,/g' -i ./src/standard.c
sed 's/(void*)main/(void*)main2/g' -i ./src/standard.c

$CC $CFLAGS -Iinclude -Iebtree  -g -DUSE_POLL -DUSE_TPROXY -DCONFIG_HAPROXY_VERSION=\"\" -DCONFIG_HAPROXY_DATE=\"\" -c -o ./src/haproxy.o ./src/haproxy.c
ar cr libetree.a ./ebtree/*.o
ar cr libhaproxy.a ./src/*.o

cp $SRC/fuzz_hpack_decode.c .
$CC $CFLAGS -Iinclude -Iebtree  -g  -DUSE_POLL -DUSE_TPROXY -DCONFIG_HAPROXY_VERSION=\"\" -DCONFIG_HAPROXY_DATE=\"\" -c fuzz_hpack_decode.c  -o fuzz_hpack_decode.o
$CXX -g $CXXFLAGS $LIB_FUZZING_ENGINE  fuzz_hpack_decode.o libhaproxy.a libetree.a -o $OUT/fuzz_hpack_decode

# Now compile more fuzzers
cp $SRC/fuzz_cfg_parser.c .
$CC $CFLAGS -Iinclude -Iebtree  -g  -DUSE_POLL -DUSE_TPROXY -DCONFIG_HAPROXY_VERSION=\"\" -DCONFIG_HAPROXY_DATE=\"\" -c -o fuzz_cfg_parser.o fuzz_cfg_parser.c
$CXX -g $CXXFLAGS $LIB_FUZZING_ENGINE  fuzz_cfg_parser.o libhaproxy.a libetree.a -o $OUT/fuzz_cfg_parser
################################################################################
