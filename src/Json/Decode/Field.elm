module Json.Decode.Field exposing (require, requireAt, attempt, attemptAt)

{-| Decode with continuation

@docs require, requireAt, attempt, attemptAt

-}

import Json.Decode as Decode exposing (Decoder)


{-| Decode required fields. The decoder will fail if the field
is missing or its value can not be decoded.

    user : Decoder User
    user =
        require "id" Decode.int <| \id ->
        require "name" Decode.string <| \name ->
        Decode.succeed
            { id = id
            , name = name
            }
-}
require : String -> Decoder a -> (a -> Decoder b) -> Decoder b
require fieldName valueDecoder continuation =
    Decode.field fieldName valueDecoder
        |> Decode.andThen continuation


{-| Decode require nested fields.

    blogPost : Decoder BlogPost
    blogPost =
        require "id" Decode.int <| \id ->
        require "title" Decode.string <| \title ->
        requireAt ["author, "name"] Decode.string <| \authorName ->
        Decode.succeed
            { id = id
            , title = title
            , author = authorName
            }
-}
requireAt : List String -> Decoder a -> (a -> Decoder b) -> Decoder b
requireAt path valueDecoder continuation =
    Decode.at path valueDecoder
        |> Decode.andThen continuation


{-| Decode optional fields.

The decoder will not fail if the field is missing or its value can no be
decoded. The decoded value will be `Nothing` if the field is missing or the
value decoder fails.

    person : Decoder Person
    person =
        require "name" Decode.string <| \name ->
        attempt "weight" Decode.int <| \maybeWeight ->
        Decode.succeed
            { name = name
            , weight = maybeWeight
            }

If a field must exist but can be null, use `require` and `Decode.maybe` instead:

    require "field" (Decode.maybe Decode.string) <| \field ->

-}
attempt : String -> Decoder a -> (Maybe a -> Decoder b) -> Decoder b
attempt fieldName valueDecoder continuation =
    Decode.maybe (Decode.field fieldName valueDecoder)
        |> Decode.andThen continuation


{-| Decode optional nested fields.

-}
attemptAt : List String -> Decoder a -> (Maybe a -> Decoder b) -> Decoder b
attemptAt path valueDecoder continuation =
    Decode.maybe (Decode.at path valueDecoder)
        |> Decode.andThen continuation


