module Main exposing (..)

import Browser
import Html exposing (Attribute, Html, div, i, img, input, table, tbody, td, text, th, thead, tr)
import Html.Attributes exposing (class, classList, colspan, id, placeholder, src, type_, value)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode exposing (Decoder, field, float, map5, string)



-- MAIN


main : Program () Model Msg
main =
    Browser.element { init = init, update = update, subscriptions = subscriptions, view = view }



-- MODEL


type alias Model =
    { countries : List Country
    , sort : Sort
    , filter : String
    }


type alias Country =
    { name : String
    , code : String
    , imageLocation : String
    , rotatedImageLocation : String
    , squareness : Float
    }


type alias Sort =
    { column : Column
    , direction : Direction
    }


type Column
    = Name
    | Squareness


type Direction
    = Ascending
    | Descending



-- Messages


type Msg
    = ChangeSort Column
    | GotData (Result Http.Error (List Country))
    | ChangeFilter String
    | ClearFilter



-- Subscriptions


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- Initial State


init : () -> ( Model, Cmd Msg )
init _ =
    ( { countries = []
      , sort =
            { column = Squareness
            , direction = Descending
            }
      , filter = ""
      }
    , Http.get
        { url = "data/countries.json"
        , expect = Http.expectJson GotData countriesDecoder
        }
    )



-- Update Functions


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeSort clickedColumn ->
            ( { model
                | sort = updateSort model.sort clickedColumn
                , countries = sortCountries model.countries model.sort
              }
            , Cmd.none
            )

        GotData result ->
            case result of
                Ok countries ->
                    ( { model | countries = sortCountries countries model.sort }
                    , Cmd.none
                    )

                Err _ ->
                    ( model, Cmd.none )

        ChangeFilter filter ->
            ( { model | filter = filter }
            , Cmd.none
            )

        ClearFilter ->
            ( { model | filter = "" }
            , Cmd.none
            )


updateSort : Sort -> Column -> Sort
updateSort currentSort clickedColumn =
    if currentSort.column == clickedColumn then
        { currentSort | direction = reverseDirection currentSort.direction }

    else
        { currentSort | column = clickedColumn }


reverseDirection : Direction -> Direction
reverseDirection sort =
    case sort of
        Ascending ->
            Descending

        Descending ->
            Ascending


sortCountries : List Country -> Sort -> List Country
sortCountries countries sort =
    List.sortWith (compareCountries sort) countries


compareCountries : Sort -> Country -> Country -> Order
compareCountries sort a b =
    case sort.column of
        Name ->
            compareWithDirection sort.direction a.name b.name

        Squareness ->
            compareWithDirection sort.direction a.squareness b.squareness


compareWithDirection : Direction -> comparable -> comparable -> Order
compareWithDirection direction a b =
    case direction of
        Ascending ->
            compare a b

        Descending ->
            case compare a b of
                LT ->
                    GT

                EQ ->
                    EQ

                GT ->
                    LT



-- View


view : { countries : List Country, sort : Sort, filter : String } -> Html Msg
view model =
    div [ class "ui container body", id "countries-segment" ]
        [ div [ class "ui fluid segment" ]
            [ div
                (List.concat
                    [ [ id "filter", class "ui input" ]
                    , addAttrIf (not (String.isEmpty model.filter)) (class "icon")
                    ]
                )
                (List.concat
                    [ [ input [ type_ "text", placeholder "Filter...", value model.filter, onInput ChangeFilter ] [] ]
                    , addElemIf (not (String.isEmpty model.filter)) (i [ class "link close icon", onClick ClearFilter ] [])
                    ]
                )
            , div [ class "content" ]
                [ table [ class "ui sortable celled table" ]
                    [ thead []
                        [ tr []
                            [ th
                                [ classList
                                    [ ( "sorted ascending", model.sort.direction == Ascending && model.sort.column == Name )
                                    , ( "sorted descending", model.sort.direction == Descending && model.sort.column == Name )
                                    ]
                                , onClick (ChangeSort Name)
                                ]
                                [ text "Name" ]
                            , th
                                [ classList
                                    [ ( "sorted ascending", model.sort.direction == Ascending && model.sort.column == Squareness )
                                    , ( "sorted descending", model.sort.direction == Descending && model.sort.column == Squareness )
                                    ]
                                , onClick (ChangeSort Squareness)
                                ]
                                [ text "Squareness" ]
                            , th [] [ text "Shape" ]
                            , th [] [ text "Rotation of Greatest Squareness" ]
                            ]
                        ]
                    , tbody [] (tableRows model)
                    ]
                ]
            ]
        ]


tableHeaderClass : Sort -> Column -> Maybe (Html.Attribute msg)
tableHeaderClass sort currentColumn =
    if sort.column == currentColumn then
        case sort.direction of
            Ascending ->
                Maybe.Just (class "ascending")

            Descending ->
                Maybe.Just (class "descending")

    else
        Maybe.Nothing


tableRows : Model -> List (Html model)
tableRows model =
    if List.length model.countries == 0 then
        [ tr []
            [ td [ colspan 4 ]
                [ div [ class "ui active centered inline text loader" ]
                    [ text "Loading"
                    ]
                ]
            ]
        ]

    else
        model.countries
            |> List.filter (\country -> shouldFilter model country)
            |> List.map tableRow


shouldFilter : Model -> Country -> Bool
shouldFilter model country =
    if String.isEmpty model.filter then
        True

    else
        containsIgnoreCase model.filter country.name || containsIgnoreCase model.filter country.code


containsIgnoreCase : String -> String -> Bool
containsIgnoreCase toLookFor toLookIn =
    toLookIn
        |> String.toLower
        |> String.contains (String.toLower toLookFor)


tableRow : Country -> Html country
tableRow country =
    tr []
        [ td [] [ text (buildCountryName country) ]
        , td [] [ text (String.fromFloat country.squareness) ]
        , td []
            [ img [ class "ui medium image", src country.imageLocation ] []
            ]
        , td []
            [ img [ class "ui medium image", src country.rotatedImageLocation ] []
            ]
        ]


buildCountryName : Country -> String
buildCountryName country =
    country.name ++ buildCountryCode country.code


buildCountryCode : String -> String
buildCountryCode countryCode =
    if countryCode == "-99" then
        ""

    else
        " (" ++ countryCode ++ ")"


addAttrIf : Bool -> Attribute msg -> List (Attribute msg)
addAttrIf isNeed attr =
    if isNeed then
        [ attr ]

    else
        []


addElemIf : Bool -> Html msg -> List (Html msg)
addElemIf isNeed attr =
    if isNeed then
        [ attr ]

    else
        []



-- Decoders


countryDecoder : Decoder Country
countryDecoder =
    map5 Country
        (field "name" string)
        (field "code" string)
        (field "imageLocation" string)
        (field "rotatedImageLocation" string)
        (field "squareness" float)


countriesDecoder : Decoder (List Country)
countriesDecoder =
    field "countries" (Decode.list countryDecoder)
