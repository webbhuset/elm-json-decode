module Json.Decode.Field exposing (..)

{-| Decode with continuation

@docs required, requiredAt, optional, optionalAt

-}

import Json.Decode as Decode exposing (Decoder)


{-| Decode required fields.

    user : Decoder User
    user =
        required "id" Json.int (\id ->
        required "name" Json.string (\name ->
            Json.succeed
                { id = id
                , name = name
                }
        ))
-}
required : String -> Decoder a -> (a -> Decoder b) -> Decoder b
required fieldName valueDecoder continuation =
    Decode.field fieldName valueDecoder
        |> Decode.andThen continuation


{-| Decode required nested fields.

    blogPost : Decoder BlogPost
    blogPost =
        required "id" Json.int (\id ->
        required "title" Json.string (\title ->
        requiredAt ["author, "name"] Json.string (\authorName ->
            Json.succeed
                { id = id
                , title = title
                , author = authorName
                }
        )))
-}
requiredAt : List String -> Decoder a -> (a -> Decoder b) -> Decoder b
requiredAt path valueDecoder continuation =
    Decode.at path valueDecoder
        |> Decode.andThen continuation


{-| Decode optional fields.

The decoder will not fail if the value is missing or null. The decoded
value will be `Nothing` if the field is missing or has value `null`.

    person : Decoder Person
    person =
        required "name" Json.string (\name ->
        optional "weight" Json.int (\maybeWeight ->
            Json.succeed
                { name = name
                , weight = maybeWeight
                }
        ))

If a field must exist but can be null, use `required` and `Json.maybe` instead:
    
    required "field" (Json.maybe Json.string)` (\field ->
    
-}
optional : String -> Decoder a -> (Maybe a -> Decoder b) -> Decoder b
optional fieldName valueDecoder continuation =
    Decode.maybe (Decode.field fieldName valueDecoder)
        |> Decode.andThen continuation


{-| Decode optional nested fields.

-}
optionalAt : List String -> Decoder a -> (Maybe a -> Decoder b) -> Decoder b
optionalAt path valueDecoder continuation =
    Decode.maybe (Decode.at path valueDecoder)
        |> Decode.andThen continuation


