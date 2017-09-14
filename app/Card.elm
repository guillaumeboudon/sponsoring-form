module Card exposing (..)

import List exposing (map)
import String exposing (slice, length, left, dropLeft, join)
import Regex


limitSize len str =
    String.slice 0 len str


splitAt pos str =
    if length str > pos then
        [ left pos str, dropLeft pos str ]
    else
        [ str ]


splitAtCouple pos str =
    ( left pos str, dropLeft pos str )


splitEvery pos str =
    if length str > pos then
        let
            ( head, tail ) =
                splitAtCouple pos str
        in
            head :: splitEvery pos tail
    else
        [ str ]


putSpacesEvery len str =
    str
        |> splitEvery len
        |> join " "


removeRegex regex text =
    text
        |> Regex.replace Regex.All (Regex.regex regex) (\_ -> "")


onlyNumbers =
    removeRegex "\\D"


onlyNumbersAndSlash =
    Regex.replace Regex.All
        (Regex.regex "\\D")
        (\{ match } ->
            if match == "/" then
                "/"
            else
                ""
        )


removeSpace =
    removeRegex " "


numberFormat text =
    text
        |> onlyNumbers
        |> limitSize 16
        |> putSpacesEvery 4


cvvFormat text =
    text
        |> onlyNumbers
        |> limitSize 4


dateFormat text =
    text
        |> onlyNumbers
        |> limitSize 6
        |> splitAt 2
        |> join " / "
