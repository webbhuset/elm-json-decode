module Json.Decode.Field exposing (..)

{-| Decode with continuation

@docs required, requiredAt, optional, optionalAt

-}

import Json.Decode as Decode exposing (Decoder)


{-| Decode required fields.
-}
required : String -> Decoder a -> (a -> Decoder b) -> Decoder b
required fieldName valueDecoder continuation =
    Decode.field fieldName valueDecoder
        |> Decode.andThen continuation


{-| Required
-}
requiredAt : List String -> Decoder a -> (a -> Decoder b) -> Decoder b
requiredAt path valueDecoder continuation =
    Decode.at path valueDecoder
        |> Decode.andThen continuation

{-| Required
-}
optional : String -> Decoder a -> (Maybe a -> Decoder b) -> Decoder b
optional fieldName valueDecoder continuation =
    Decode.maybe (Decode.field fieldName valueDecoder)
        |> Decode.andThen continuation


{-| Required
-}
optionalAt : List String -> Decoder a -> (Maybe a -> Decoder b) -> Decoder b
optionalAt path valueDecoder continuation =
    Decode.maybe (Decode.at path valueDecoder)
        |> Decode.andThen continuation


