#!/bin/bash

string='usr/src/linux-4.3.3-GRSRV/tools/perf/arch/common.h'
#string='usr/src/linux-4.3.3-GRSRV/tools/perf/arch/x86/common.h'
#string='usr/src/linux-4.3.3-GRSRV/tools/perf/arch/arm/common.h'

if [[ "$string" =~ /arch/.*/ ]] && ! [[ "$string" =~ "/arch/x86/" ]]; then
    echo 'dont add'
fi
