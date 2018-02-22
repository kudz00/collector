/** collector

A full notice with attributions is provided along with this source code.

This program is free software; you can redistribute it and/or modify it under the terms of the GNU General Public License version 2 as published by the Free Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program; if not, write to the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

* In addition, as a special exception, the copyright holders give
* permission to link the code of portions of this program with the
* OpenSSL library under certain conditions as described in each
* individual source file, and distribute linked combinations
* including the two.
* You must obey the GNU General Public License in all respects
* for all of the code used other than OpenSSL.  If you modify
* file(s) with this exception, you may extend this exception to your
* version of the file(s), but you are not obligated to do so.  If you
* do not wish to do so, delete this exception statement from your
* version.
*/

#include <iostream>
#include <chrono>
#include <string>

#include "SysdigService.h"
#include "CollectorStatsExporter.h"

#include "prometheus/registry.h"

extern "C" {
    #include <pthread.h>
    #include <string.h>
}

namespace collector {

CollectorStatsExporter::CollectorStatsExporter(std::shared_ptr<prometheus::Registry> registry, SysdigService* sysdig)
    : registry_(std::move(registry)), sysdig_(sysdig)
{}

bool CollectorStatsExporter::start() {
    if (!thread_.Start(&CollectorStatsExporter::run, this)) {
        std::cerr << "Could not start sysdig stats exporter: already running" << std::endl;
        return false;
    }
    return true;
}

void CollectorStatsExporter::run() {
    auto& collectorEventCounters = prometheus::BuildGauge()
        .Name("rox_collector_events")
        .Help("Collector events")
        .Register(*registry_);

    auto& kernel = collectorEventCounters.Add({{"type", "kernel"}});
    auto& drops = collectorEventCounters.Add({{"type", "drops"}});
    auto& preemptions = collectorEventCounters.Add({{"type", "preemptions"}});
    auto& filtered = collectorEventCounters.Add({{"type", "filtered"}});
    auto& userspaceEvents = collectorEventCounters.Add({{"type", "userspace"}});
    auto& kafkaSendFailures = collectorEventCounters.Add({{"type", "kafkaSendFailures"}});

    while (thread_.Pause(std::chrono::seconds(1))) {
        SysdigStats stats;
        if (!sysdig_->GetStats(&stats)) {
            continue;
        }

        kernel.Set(stats.nEvents);
        drops.Set(stats.nDrops);
        preemptions.Set(stats.nPreemptions);
        filtered.Set(stats.nFilteredEvents);
        userspaceEvents.Set(stats.nUserspaceEvents);
        kafkaSendFailures.Set(stats.nKafkaSendFailures);
    }
}

void CollectorStatsExporter::stop()
{
    thread_.Stop();
}


}  // namespace collector

