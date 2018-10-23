module Util.IntervalFuzzer exposing (interval)

import Fuzz exposing (Fuzzer)
import List.Extra
import MusicTheory.Interval as Interval
import Util.Fuzzer


interval : Fuzzer Interval.Interval
interval =
    Util.Fuzzer.fromList Interval.all
