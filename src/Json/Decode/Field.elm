module Json.Decode.Field exposing (require, requireAt, attempt, attemptAt)

{-| # Decode JSON objects

Since JSON values are not known until runtime there is no way
of checking them at compile time. This means that there is a
possibility a decoding operation can not be successfully completed.

In that case there are two possible solutions:

1. Fail the whole decoding operation.
2. Deal with the missing value situation, either by defaulting to some value or by
   using a `Maybe` value

In this module these two options are represented by `requre` and
`attempt`.

* `requre` will fail if:
    - It was not run on an object.
    - The field was missing.
    - The field's value could not be decoded.
* `attempt` will never fail. It always decodes to a `Maybe` value.

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


{-| Decode nested fields. Works the same as `requre` but on nested fieds.

    blogPost : Decoder BlogPost
    blogPost =
        require "id" Decode.int <| \id ->
        require "title" Decode.string <| \title ->
        requireAt ["author", "name"] Decode.string <| \authorName ->

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

Always decodes to a `Maybe` value and never fails.

The decoder will not fail if the field is missing or its value can no be
decoded. The decoded value will be `Nothing` in that case.

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


{-| Decode optional nested fields. Works the same way as `attempt` but on nested fields.

-}
attemptAt : List String -> Decoder a -> (Maybe a -> Decoder b) -> Decoder b
attemptAt path valueDecoder continuation =
    Decode.maybe (Decode.at path valueDecoder)
        |> Decode.andThen continuation


