module MusicTheory.PitchClass exposing
    ( areEnharmonicEqual
    , Accidental(..), Letter(..), PitchClass, all, asNaturalOrLoweredOnce, asNaturalOrRaisedOnce, exact, fromTuple, pitchClass, semitones, toString, transposeBySemitones, transposeDown, transposeUp
    )

{-| A pitch class is a set of all pitches that are a whole number of octaves apart. A pitch class is represented as a letter together with an accidental.

The internals of `PitchClass` are opaque. By using accessor functions the caller can get specific enharmonic equivalent pitch classes depending on their needs.


# Definition

@docs Letter Accidental PitchClass


# Constructors

@docs pitchClass fromTuple


# Accessors

@docs exact all


# Transform

@docs transposeUp transposeDown transposeBySemitones equivalentAsNaturalOrFlat equivalentAsNaturalOrSharp semitones toString


# Comparison

@docs areEnharmonicEqual

-}

import MusicTheory.Interval as Interval exposing (Interval, IntervalNumber(..), IntervalQuality(..))



-- DEFINITION


{-| A letter represents a note from the diatonic C major scale.
-}
type Letter
    = C
    | D
    | E
    | F
    | G
    | A
    | B


{-| An accidental describes by how many semitones a letter is raised or lowered.
-}
type Accidental
    = TripleFlat
    | DoubleFlat
    | Flat
    | Natural
    | Sharp
    | DoubleSharp
    | TripleSharp


{-| Internal representation of an unlimited raised or lowered letter. E.g. four flats are represented as as `Offset -4`.
-}
type Offset
    = Offset Int


{-| Opaque type that represents a pitch class.
-}
type PitchClass
    = PitchClass Letter Offset



-- CONSTRUCTORS


{-| Create a pitch class from a letter and an accidental.

    pitchClass C Sharp -- creates the pitch class C♯

-}
pitchClass : Letter -> Accidental -> PitchClass
pitchClass l acc =
    PitchClass l (accidentalToOffset acc)


{-| Create a pitch class from a tuple of a letter and an accidental.

    fromTuple ( G, Flat ) -- creates the pitch class G♭

-}
fromTuple : ( Letter, Accidental ) -> PitchClass
fromTuple ( l, acc ) =
    pitchClass l acc



-- ACCESSORS


{-| A list of all pitch classes that can be represented in terms of `Letter` and an `Accidental`.
-}
all : List PitchClass
all =
    letters
        |> List.concatMap (\l -> accidentals |> List.map (pitchClass l))


{-| Returns the letter and accidental of a pitch class if the letter is raised or lowered such that it can be expressed in terms of a valid accidental.

    (pitchClass F Sharp |> exact) == Just ( F, Sharp )

-}
exact : PitchClass -> Maybe ( Letter, Accidental )
exact (PitchClass l o) =
    offsetToAccidental o
        |> Maybe.map (Tuple.pair l)


letter : PitchClass -> Letter
letter (PitchClass l _) =
    l


offset : PitchClass -> Int
offset (PitchClass _ (Offset n)) =
    n



-- TRANSFORM


{-| Number of semitones between C and a given pitch class.

    semitones (pitchClass E Natural) == 4

-}
semitones : PitchClass -> Int
semitones pc =
    modBy (exactSemitones pc) 12


exactSemitones : PitchClass -> Int
exactSemitones (PitchClass l (Offset n)) =
    letterSemitones l + n


{-| Returns the enharmonic equivalent pitch class expressed as a note from the diatonic C major scale that is natural or raised once

    asNaturalOrRaisedOnce (pitchClass F DoubleSharp) == ( G, Natural )

    asNaturalOrRaisedOnce (pitchClass C TripleSharp) == ( D, Sharp )

-}
asNaturalOrRaisedOnce : PitchClass -> ( Letter, Accidental )
asNaturalOrRaisedOnce pc =
    case pc |> semitones |> semitonesToNaturalOrAccidental of
        Nat l ->
            ( l, Natural )

        SharpFlat l _ ->
            ( l, Sharp )


{-| Returns the enharmonic equivalent pitch class expressed as a note from the diatonic C major scale that is natural or lowered once.

    asNaturalOrLoweredOnce (pitchClass F DoubleSharp) == ( G, Natural )

    asNaturalOrLoweredOnce (pitchClass C TripleSharp) == ( E, Flat )

-}
asNaturalOrLoweredOnce : PitchClass -> ( Letter, Accidental )
asNaturalOrLoweredOnce pc =
    case pc |> semitones |> semitonesToNaturalOrAccidental of
        Nat l ->
            ( l, Natural )

        SharpFlat _ l ->
            ( l, Flat )


{-| String representation of a letter and an accidental.

    toString ( D, Sharp ) == "D♯"

-}
toString : ( Letter, Accidental ) -> String
toString ( l, acc ) =
    accidentalToString acc ++ letterToString l



-- TRANSPOSE


{-| Moves a pitch class up by a given interval while taking the correct number off staff positions between root and target pitch class into account.

    (pitchClass C Sharp |> transposeUp Interval.majorSecond |> exact) == Just (D, Sharp)

    The result might not be representable in terms of the correct letter and a valid accidental. In this case a suitable enharmonic representation can be retrieved by applying `asNaturalOrLoweredOnce` or `asNaturalOrRaisedOnce`.

    (pitchClass C TripleFlat |> transposeUp Interval.minorSecond |> exact) == Nothing

    (pitchClass C TripleFlat |> transposeUp Interval.minorSecond |> asNaturalOrLoweredOnce) == (B, Flat)

-}
transposeUp : Interval -> PitchClass -> PitchClass
transposeUp interval pc =
    let
        ( targetLetter, letterToLetterDistance ) =
            targetLetterWithSemitoneDistance (letterIndex (letter pc)) (intervalNumberIndex (Interval.number interval)) ( letter pc, 0 )
    in
    PitchClass targetLetter (Offset (Interval.semitones interval - letterToLetterDistance + offset pc))


{-| Moves a pitch class down by a given interval while taking the correct number off staff positions between root and target pitch class into account.

    (pitchClass B Natural |> transposeDown Interval.minorSecond) == pitchClass A Sharp

-}
transposeDown : Interval -> PitchClass -> PitchClass
transposeDown interval pc =
    interval
        |> Interval.complementary
        |> (\i -> transposeUp i pc)


{-| Moves a pitch class by a given number of semitones. The result will be ambiguous because while transposing by semitones alone it cannot be determined which enharmonic equivalent pitch class to choose as the result. An enharmonic equivalent representation can be retrieved by applying `asNaturalOrLoweredOnce` or `asNaturalOrRaisedOnce`.

    (pitchClass C Natural |> transposeBySemitones 10 |> asNaturalOrLoweredOnce) == ( B, Flat )

    (pitchClass C Natural |> transposeBySemitones 10 |> asNaturalOrRaisedOnce) == ( A, Sharp )

-}
transposeBySemitones : Int -> PitchClass -> PitchClass
transposeBySemitones n (PitchClass l (Offset off)) =
    PitchClass l (Offset (off + n))



-- COMPARISON


{-| Returns true if two pitch classes are enharmonic equivalent.
-}
areEnharmonicEqual : PitchClass -> PitchClass -> Bool
areEnharmonicEqual lhs rhs =
    semitones lhs == semitones rhs



-- INTERNALS


accidentalToOffset : Accidental -> Offset
accidentalToOffset acc =
    case acc of
        TripleFlat ->
            Offset -3

        DoubleFlat ->
            Offset -2

        Flat ->
            Offset -1

        Natural ->
            Offset 0

        Sharp ->
            Offset 1

        DoubleSharp ->
            Offset 2

        TripleSharp ->
            Offset 3


offsetToAccidental : Offset -> Maybe Accidental
offsetToAccidental (Offset n) =
    if n == -3 then
        Just TripleFlat

    else if n == -2 then
        Just DoubleFlat

    else if n == -1 then
        Just Flat

    else if n == 0 then
        Just Natural

    else if n == 1 then
        Just Sharp

    else if n == 2 then
        Just DoubleSharp

    else if n == 3 then
        Just TripleSharp

    else
        Nothing


letters : List Letter
letters =
    [ C, D, E, F, G, A, B, C ]


accidentals : List Accidental
accidentals =
    [ TripleFlat, DoubleFlat, Flat, Natural, Sharp, DoubleSharp, TripleSharp ]


letterSemitones : Letter -> Int
letterSemitones l =
    case l of
        C ->
            0

        D ->
            2

        E ->
            4

        F ->
            5

        G ->
            7

        A ->
            9

        B ->
            11


type NaturalOrAccidental
    = Nat Letter
    | SharpFlat Letter Letter


semitonesToNaturalOrAccidental : Int -> NaturalOrAccidental
semitonesToNaturalOrAccidental off =
    if off == -3 then
        Nat A

    else if off == -2 then
        SharpFlat A B

    else if off == -1 then
        Nat B

    else if off == 0 then
        Nat C

    else if off == 1 then
        SharpFlat C D

    else if off == 2 then
        Nat D

    else if off == 3 then
        SharpFlat D E

    else if off == 4 then
        Nat E

    else if off == 5 then
        Nat F

    else if off == 6 then
        SharpFlat F G

    else if off == 7 then
        Nat G

    else if off == 8 then
        SharpFlat G A

    else if off == 9 then
        Nat A

    else if off == 10 then
        SharpFlat A B

    else if off == 11 then
        Nat B

    else if off == 12 then
        Nat C

    else if off == 13 then
        SharpFlat C D

    else if off == 14 then
        Nat D

    else if off > 14 then
        semitonesToNaturalOrAccidental (off - 12)

    else
        semitonesToNaturalOrAccidental (off + 12)


letterToString : Letter -> String
letterToString letterName =
    case letterName of
        C ->
            "C"

        D ->
            "D"

        E ->
            "E"

        F ->
            "F"

        G ->
            "G"

        A ->
            "A"

        B ->
            "B"


accidentalToString : Accidental -> String
accidentalToString acc =
    case acc of
        TripleFlat ->
            "♭𝄫"

        DoubleFlat ->
            "𝄫"

        Flat ->
            "♭"

        Natural ->
            ""

        Sharp ->
            "♯"

        DoubleSharp ->
            "𝄪"

        TripleSharp ->
            "♯𝄪"


letterIndex : Letter -> Int
letterIndex l =
    case l of
        C ->
            0

        D ->
            1

        E ->
            2

        F ->
            3

        G ->
            4

        A ->
            5

        B ->
            6


intervalNumberIndex : IntervalNumber -> Int
intervalNumberIndex intervalNumber =
    case intervalNumber of
        Unison ->
            0

        Second ->
            1

        Third ->
            2

        Fourth ->
            3

        Fifth ->
            4

        Sixth ->
            5

        Seventh ->
            6

        Octave ->
            7


letterAndSemitoneStepsByIndex : Int -> ( Letter, Int )
letterAndSemitoneStepsByIndex n =
    case n of
        0 ->
            ( C, 1 )

        1 ->
            ( D, 2 )

        2 ->
            ( E, 2 )

        3 ->
            ( F, 1 )

        4 ->
            ( G, 2 )

        5 ->
            ( A, 2 )

        6 ->
            ( B, 2 )

        other ->
            if other < 0 then
                letterAndSemitoneStepsByIndex (other + 7)

            else
                letterAndSemitoneStepsByIndex (other - 7)


targetLetterWithSemitoneDistance : Int -> Int -> ( Letter, Int ) -> ( Letter, Int )
targetLetterWithSemitoneDistance currentIndex steps ( currentLetter, totalSemitones ) =
    if steps <= 0 then
        ( currentLetter, totalSemitones )

    else
        let
            ( currentTargetLetter, stepSemitones ) =
                letterAndSemitoneStepsByIndex (currentIndex + 1)
        in
        targetLetterWithSemitoneDistance (currentIndex + 1) (steps - 1) ( currentTargetLetter, totalSemitones + stepSemitones )