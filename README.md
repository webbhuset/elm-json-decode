# Field Decoder, Continuation

This packages lets you write JSON decoders in a [Continuation-passing style](https://en.wikipedia.org/wiki/Continuation-passing_style).
This is useful when decoding JSON objects to Elm records.

```elm

import Json.Decode as Json exposing (Decoder)
import Json.Decode.Field as Field

type alias Person =
    { id : Int
    , name : String
    , maybeWeight : Maybe Int
    , likes : Int
    , hardcoded : String
    }


decodeUsingMap : Decoder Person
decodeUsingMap =
    Json.map5 Person
        (Json.field "id" Json.int)
        (Json.field "name" Json.string)
        (Json.maybe <| Json.field "weight" Json.int)
        (Json.maybe (Json.field "likes" Json.int)
            |> Json.map (Maybe.withDefault 0)
        )
        (Json.succeed "Hardcoded Value")


decodeUsingContinuation : Decoder Person
decodeUsingContinuation =
    Field.required "name" Json.string (\name ->
    Field.required "id" Json.int (\id ->
    Field.optional "weight" Json.int (\maybeWeight ->
    Field.optional "likes" Json.int (\maybeLikes ->
        Json.succeed
            { name = name
            , id = id
            , maybeWeight = maybeWeight
            , likes = Maybe.withDefault 0 maybeLikes
            , hardcoded = "Hardcoded value"
            }
    ))))
```


## What is going on?

Consider this simple example:

```elm
import Json.Decode as Json exposing (Decoder)

type alias User =
    { id : Int
    , name : String
    }


user : Decoder User
user =
    Json.map2 User
        (Json.field "id" Json.int)
        (Json.field "name" Json.string)
```

Here, `map2` from elm/json is used to decode a JSON object to a record.
The record constructor function is used (`User : Int -> String -> User`) to build the record.
This means that the order fields are written in the type declaration matters. If you
change the order of `id` and `name`, you have to change the order of the two 
`Json.field ...` rows to match the order of the record.

To use named bindings instead you can write a decoder like this:

```elm
user : Decoder User
user =
    Json.field "id" Json.int
        |> Json.andThen
            (\id ->
                Json.field "name" Json.string
                    |> Json.andThen
                        (\name ->
                            Json.succeed
                                { id = id
                                , name = name
                                }
                        )
            )
```
Now this looks ridicolus, but one thing is interesting: The record is
constructed using named variables (the innermost function).

The above code can be improved by using the helper function `required`. This is
the same idea expressed in a cleaner way:

```elm
import Json.Decode.Field as Field

user : Decoder User
user =
    Field.required "id" Json.int
        (\id ->
            Field.required "name" Json.string
                (\name ->
                    Json.succeed
                        { id = id
                        , name = name
                        }
                )
        )
```

Finally, if you format the code like this it gets even more clear
what is going on:

```elm
user : Decoder User
user =
    Field.required "id" Json.int (\id ->
    Field.required "name" Json.string (\name ->
        Json.succeed
            { id = id
            , name = name
            }
    ))
```

