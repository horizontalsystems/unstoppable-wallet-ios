import Foundation

class UptimeProvider: IUptimeProvider {

    var uptime: TimeInterval {
        var uptime = timespec()
        clock_gettime(CLOCK_MONOTONIC_RAW, &uptime)
        return TimeInterval(uptime.tv_sec)
    }

}
