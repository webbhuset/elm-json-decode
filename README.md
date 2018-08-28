# JSON Decoder, continuation-passing style

This packages helps you writing JSON decoders in a [Continuation-passing style](https://en.wikipedia.org/wiki/Continuation-passing_style).
This is useful when decoding JSON objects to Elm records.

## Example

Let's say you have a `Person` record looking like this:

```elm
type alias Person =
    { id : Int -- Field is mandatory, decoder should fail if field is missing in the JSON object
    , name : String -- Field is mandatory
    , maybeWeight : Maybe Int -- Field is optional in the JSON object
    , likes : Int -- Should default to 0 if JSON field is missing or null
    , hardcoded : String -- Should be hardcoded to "Hardcoded Value"
    }
```
The traditional approach would be to use `Json.Decode.mapX` to build records.

```elm
import Json.Decode as Json exposing (Decoder)

person : Decoder Person
person =
    Json.map5 Person
        (Json.field "id" Json.int)
        (Json.field "name" Json.string)
        (Json.maybe <| Json.field "weight" Json.int)
        (Json.field "likes" Json.int
            |> Json.maybe
            |> Json.map (Maybe.withDefault 0)
        )
        (Json.succeed "Hardcoded Value")
```

Using this package you can write the same decoder like this:
```elm
import Json.Decode as Json exposing (Decoder)
import Json.Decode.Field as Field

person : Decoder Person
person =
    Field.required "name" Json.string (\name ->
    Field.required "id" Json.int (\id ->
    Field.optional "weight" Json.int (\maybeWeight ->
    Field.optional "likes" Json.int (\maybeLikes ->
        Json.succeed
            { name = name
            , id = id
            , maybeWeight = maybeWeight
            , likes = Maybe.withDefault 0 maybeLikes
            , hardcoded = "Hardcoded Value"
            }
    ))))
```

The main advantages over using `mapX` are:

* Record field order does not matter. Named binding is used instead of order. You can change the order of the fields in the type declaration (`type alias Person ...`) without breaking things.
* Easier to see how the record is connected to the JSON object. Especially when there are many fields. Sometimes the JSON fields have different names than your Elm record.
* Easier to add fields down the line.
* If all fields of the record has the same type you won't get any compiler error with the `map` approach if you mess up the order. Since named binding is used here it makes it much easier to get things right.
* Sometimes fields needs futher validation / processing. See below examples.

## More Examples

### Combine fields

In this example the JSON object contains both `firstname` and `lastname`, but the Elm record only has `name`.

```elm

type alias Person =
    { name : String
    , age : Int
    }
    
person : Decoder Person
person =
    Field.required "firstname" Json.string (\firstname ->
    Field.required "lastname" Json.string (\lastname ->
    Field.required "age" Json.int (\int ->
        Json.succeed
            { name = firstname ++ " " ++ lastname
            , age = age
            }
    )))
```

### Fail decoder if values are invalid

Here, the decoder should fail if the person is below 18.

```elm
type alias Person =
    { name : String
    , age : Int
    }
    
person : Decoder Person
person =
    Field.required "name" Json.string (\name ->
    Field.required "age" Json.int (\int ->
        if age < 18 then
            Json.fail "You must be an adult"
        else
            Json.succeed
                { name = name
                , age = age
                }
    ))
```


## How does this work?

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
change the order of fields `id` and `name` in yor record, you have to change the order of the two 
`(Json.field ...)` rows to match the order of the record.

To use named bindings instead you can use `Json.Decode.andThen` write a decoder like this:

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

The fields are decoded one at the time and then the decoded value is bound to a
contiunation function using `andThen`.

The above code can be improved by using the helper function `required`. This is
the same decoder expressed in a cleaner way:

```elm
module Json.Decode.Field exposing (required)

required : String -> Decoder a -> (a -> Decoder b) -> Decoder b
required fieldName valueDecoder continuation =
    Json.field fieldName valueDecoder
        |> Json.andThen continuation

-- In User.elm
module User exposing (user)

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
Now we got rid of some `andThen` noise.

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
This reads quite nice.

First you extract everything you need from the JSON object and
bind each field to a variable. Keeping the field decoder and the variable on the same row makes it
easy to read.
Then you build the record using all collected values.

