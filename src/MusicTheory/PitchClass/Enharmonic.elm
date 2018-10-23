module MusicTheory.PitchClass.Enharmonic exposing (asNaturalOrElseFlat, asNaturalOrElseSharp, equivalents, simple)

import MusicTheory.Internal.PitchClass as PitchClass exposing (Offset(..), PitchClass(..))
import MusicTheory.Internal.PitchClass.Enharmonic as Enharmonic exposing (NaturalOrSingleAccidental(..))


simple : PitchClass -> PitchClass
simple pc =
    if PitchClass.offset pc == 0 then
        pc

    else if PitchClass.offset pc < 0 then
        asNaturalOrElseFlat pc

    else
        asNaturalOrElseSharp pc


asNaturalOrElseFlat : PitchClass -> PitchClass
asNaturalOrElseFlat pc =
    case pc |> PitchClass.semitones |> Enharmonic.semitonesToNaturalOrAccidental of
        Nat letter ->
            PitchClass.pitchClass letter (Offset 0)

        SharpFlat _ letter ->
            PitchClass.pitchClass letter (Offset -1)


asNaturalOrElseSharp : PitchClass -> PitchClass
asNaturalOrElseSharp pc =
    case pc |> PitchClass.semitones |> Enharmonic.semitonesToNaturalOrAccidental of
        Nat letter ->
            PitchClass.pitchClass letter (Offset 0)

        SharpFlat letter _ ->
            PitchClass.pitchClass letter (Offset 1)


equivalents : PitchClass -> List PitchClass
equivalents pc =
    PitchClass.all |> List.filter (PitchClass.semitones >> (==) (PitchClass.semitones pc))
