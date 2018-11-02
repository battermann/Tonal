module MusicTheory.Music exposing
    ( Control(..)
    , Music(..)
    , aFlat
    , aNatural
    , aSharp
    , addDuration
    , bFlat
    , bNatural
    , bSharp
    , cFlat
    , cNatural
    , cSharp
    , chord
    , dFlat
    , dNatural
    , dSharp
    , eFlat
    , eNatural
    , eSharp
    , eighthNoteTriplet
    , fFlat
    , fNatural
    , fSharp
    , gFlat
    , gNatural
    , gSharp
    , key
    , line
    , map
    , modify
    , note
    , pMap
    , pToList
    , par
    , quarterNoteTriplet
    , rest
    , seq
    , tempo
    , timeSignature
    , times
    , toList
    )

import MusicTheory.Duration as Duration exposing (Duration)
import MusicTheory.Key exposing (Key)
import MusicTheory.Letter exposing (Letter(..))
import MusicTheory.Octave exposing (Octave)
import MusicTheory.Pitch as Pitch exposing (Pitch)
import MusicTheory.Tuplet as Tuplet exposing (Tuplet)



-- TYPES


type alias Primitive a =
    ( Duration, List a )


type alias Bpm =
    Float


type Control
    = Tuplet Tuplet
    | KeySignature Key
    | TimeSignature Int Int
    | Tempo Duration Bpm


type Music a
    = Prim (Primitive a)
    | Seq (Music a) (Music a)
    | Par (Music a) (Music a)
    | Modify Control (Music a)



-- CONSTRUCTORS


note : Duration -> a -> Music a
note duration a =
    Prim <| ( duration, [ a ] )


rest : Duration -> Music a
rest duration =
    Prim <| ( duration, [] )


seq : Music a -> Music a -> Music a
seq =
    Seq


par : Music a -> Music a -> Music a
par =
    Par


key : Key -> Music a -> Music a
key k =
    modify (KeySignature k)


timeSignature : Int -> Int -> Music a -> Music a
timeSignature beats duration =
    modify (TimeSignature beats duration)


tempo : Duration -> Float -> Music a -> Music a
tempo d t =
    modify <| Tempo d t


modify : Control -> Music a -> Music a
modify =
    Modify


quarterNoteTriplet : (Duration -> Music a) -> (Duration -> Music a) -> (Duration -> Music a) -> Music a
quarterNoteTriplet m1 m2 m3 =
    modify (Tuplet (Tuplet.triplet Tuplet.Quarter)) (line [ m1 Duration.quarterNote, m2 Duration.quarterNote, m3 Duration.quarterNote ])


eighthNoteTriplet : (Duration -> Music a) -> (Duration -> Music a) -> (Duration -> Music a) -> Music a
eighthNoteTriplet m1 m2 m3 =
    modify (Tuplet (Tuplet.triplet Tuplet.Eighth)) (line [ m1 Duration.eighthNote, m2 Duration.eighthNote, m3 Duration.eighthNote ])



-- NOTE CONSTRUCTORS


cFlat : Octave -> Duration -> Music Pitch
cFlat o duration =
    note duration (Pitch.pitch C Pitch.flat o)


cNatural : Octave -> Duration -> Music Pitch
cNatural o duration =
    note duration (Pitch.pitch C Pitch.natural o)


cSharp : Octave -> Duration -> Music Pitch
cSharp o duration =
    note duration (Pitch.pitch C Pitch.sharp o)


dFlat : Octave -> Duration -> Music Pitch
dFlat o duration =
    note duration (Pitch.pitch D Pitch.flat o)


dNatural : Octave -> Duration -> Music Pitch
dNatural o duration =
    note duration (Pitch.pitch D Pitch.natural o)


dSharp : Octave -> Duration -> Music Pitch
dSharp o duration =
    note duration (Pitch.pitch D Pitch.sharp o)


eFlat : Octave -> Duration -> Music Pitch
eFlat o duration =
    note duration (Pitch.pitch E Pitch.flat o)


eNatural : Octave -> Duration -> Music Pitch
eNatural o duration =
    note duration (Pitch.pitch E Pitch.natural o)


eSharp : Octave -> Duration -> Music Pitch
eSharp o duration =
    note duration (Pitch.pitch E Pitch.sharp o)


fFlat : Octave -> Duration -> Music Pitch
fFlat o duration =
    note duration (Pitch.pitch F Pitch.flat o)


fNatural : Octave -> Duration -> Music Pitch
fNatural o duration =
    note duration (Pitch.pitch F Pitch.natural o)


fSharp : Octave -> Duration -> Music Pitch
fSharp o duration =
    note duration (Pitch.pitch F Pitch.sharp o)


gFlat : Octave -> Duration -> Music Pitch
gFlat o duration =
    note duration (Pitch.pitch G Pitch.flat o)


gNatural : Octave -> Duration -> Music Pitch
gNatural o duration =
    note duration (Pitch.pitch G Pitch.natural o)


gSharp : Octave -> Duration -> Music Pitch
gSharp o duration =
    note duration (Pitch.pitch G Pitch.sharp o)


aFlat : Octave -> Duration -> Music Pitch
aFlat o duration =
    note duration (Pitch.pitch A Pitch.flat o)


aNatural : Octave -> Duration -> Music Pitch
aNatural o duration =
    note duration (Pitch.pitch A Pitch.natural o)


aSharp : Octave -> Duration -> Music Pitch
aSharp o duration =
    note duration (Pitch.pitch A Pitch.sharp o)


bFlat : Octave -> Duration -> Music Pitch
bFlat o duration =
    note duration (Pitch.pitch B Pitch.flat o)


bNatural : Octave -> Duration -> Music Pitch
bNatural o duration =
    note duration (Pitch.pitch B Pitch.natural o)


bSharp : Octave -> Duration -> Music Pitch
bSharp o duration =
    note duration (Pitch.pitch B Pitch.sharp o)



-- FUNCTIONS


line : List (Music a) -> Music a
line ms =
    case ms of
        [] ->
            rest Duration.zero

        [ m ] ->
            m

        h :: t ->
            List.foldl (\m1 m2 -> seq m2 m1) h t


chord : List (Duration -> Music a) -> Duration -> Music a
chord ms duration =
    case ms of
        [] ->
            rest Duration.zero

        [ m ] ->
            m duration

        h :: t ->
            List.foldl (\m1 m2 -> par m2 (m1 duration)) (h duration) t


pToList : Primitive a -> List a
pToList =
    Tuple.second


pMap : (a -> b) -> Primitive a -> Primitive b
pMap f p =
    p |> Tuple.mapSecond (List.map f)


map : (a -> b) -> Music a -> Music b
map f music =
    case music of
        Prim group ->
            Prim (pMap f group)

        Seq m1 m2 ->
            Seq (map f m1) (map f m2)

        Par m1 m2 ->
            Par (map f m1) (map f m2)

        Modify control m ->
            Modify control (map f m)


toList : Music a -> List a
toList music =
    case music of
        Prim prim ->
            pToList prim

        Seq m1 m2 ->
            toList m1 ++ toList m2

        Par m1 m2 ->
            toList m1 ++ toList m2

        Modify _ m ->
            toList m


times : Int -> Music a -> Music a
times n m =
    if n <= 0 then
        rest Duration.zero

    else
        m |> seq (times (n - 1) m)


addDuration : Duration -> List (Duration -> Music a) -> Music a
addDuration duration =
    List.map (\n -> n duration) >> line
