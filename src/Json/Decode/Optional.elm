module Json.Decode.Optional exposing
    ( OptionalDecoder, at, return
    , Error, decodeString, decodeValue
    )

{-|


# Optional decoder

This module helps you create a Json Decoder that will never fail.
This is useful when you want to decode a record but not
fail if something is wrong.

This could of course be achieved by defaulting if the normal decoder fails:

    Json.Decode.decodeValue recordDecoder value
        |> Result.withDefault defaultRecord

The problem with this approach is that if one field is faulty the
whole record will be defaulted. In some cases you want to decode
everything possible and only use default for fields that couldn't
be decoded.

This decoder will always succeed with a value and a list of errors.

```
import Json.Decode as Decode

decoder =
    at ["field1"] Decode.string "Default 1" <| \value1 ->
    at ["field2"] Decode.string "Default 2" <| \value2 ->
    return
        { field1 = value1
        , field2 = value2
        }
```

Running the decoder with this Json value:

```
{
    "field1": "Hello",
    "field2": null
}
```

Will result in the record:

```
{ field1 = "Hello"
, field2 = "Default 2"
}
```

and a list of `Error`:

```
[ { path = ["field2"]
  , error = Field "field2" (Failure ("Expecting a STRING") <internals>)
  }
]
```

## Create an Optional Decoder

@docs OptionalDecoder, at, return


## Run OptionalDecoder

@docs Error, decodeString, decodeValue

-}

import Json.Decode as Decode


type alias JsonDecoder a =
    Decode.Decoder a


{-| A decoder that never fails.
-}
type OptionalDecoder a
    = OptionalDecoder (JsonDecoder ( List Error, a ))


{-| A decode error.
-}
type alias Error =
    { path : List String
    , error : Decode.Error
    }


type alias TestRecord =
    { field1 : String
    , field2 : String
    }


test =
    let
        decoder : OptionalDecoder TestRecord
        decoder =
            at ["field1"] Decode.string "Default 1" <| \value1 ->
            at ["field2"] Decode.string "Default 2" <| \value2 ->
            return
                { field1 = value1
                , field2 = value2
                }

        json =
            """
{ "field1": "Hello"
, "field2": null
}
"""
    in
    decodeString decoder json


{-| Decode a field with an optional value

    at <path> <decoder> <default value> <continuation>

    at ["field1"] Decode.string "1" <| \value1 ->
    at ["field2"] Decode.int 2 <| \value2 ->
    return
        { field1 = value1
        , field2 = value2
        }
-}
at : List String -> JsonDecoder a -> a -> (a -> OptionalDecoder b) -> OptionalDecoder b
at path decoder defaultValue continuation =
    Decode.value
        |> Decode.andThen
            (\jsonValue ->
                let
                    fieldDecoder =
                        Decode.at path decoder
                in
                case Decode.decodeValue fieldDecoder jsonValue of
                    Ok value ->
                        let
                            (OptionalDecoder result) =
                                continuation value
                        in
                        result

                    Err decodeError ->
                        let
                            (OptionalDecoder result) =
                                continuation defaultValue
                        in
                        result
                            |> Decode.map
                                (\( errors, value ) ->
                                    ( { path = path
                                      , error = decodeError
                                      }
                                        :: errors
                                    , value
                                    )
                                )
            )
        |> OptionalDecoder


{-| Return a value from your decoder.
-}
return : a -> OptionalDecoder a
return arg =
    Decode.succeed
        ( []
        , arg
        )
        |> OptionalDecoder


{-| Decode a json string
-}
decodeString : OptionalDecoder a -> String -> ( List Error, a )
decodeString (OptionalDecoder decoder) value =
    case Decode.decodeString decoder value of
        Ok v ->
            v

        Err e ->
            -- This decoder can never fail so this will never happen (hopefully).
            decodeString (OptionalDecoder decoder) value


{-| Decode a Json value
-}
decodeValue : OptionalDecoder a -> Decode.Value -> ( List Error, a )
decodeValue (OptionalDecoder decoder) value =
    case Decode.decodeValue decoder value of
        Ok v ->
            v

        Err e ->
            -- This decoder can never fail so this will never happen (I hope).
            decodeValue (OptionalDecoder decoder) value
