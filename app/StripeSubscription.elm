port module StripeSubscription exposing (..)

import Http
import BodyBuilder exposing (..)
import Elegant exposing (..)
import Color
import Json.Decode as Decode
import Json.Encode as Encode
import Card
import Function exposing (..)


main : Program Never Model Msg
main =
    program
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }



-- MODEL


init : ( Model, Cmd Msg )
init =
    ( initialModel, Cmd.none )


initialModel : Model
initialModel =
    { currentPage = StripeForm
    , stripePlan = Mensual
    , token = Nothing
    , creditCard = initialCreditCardModel
    , subscriptionResult = Nothing
    }


initialCreditCardModel : CreditCardModel
initialCreditCardModel =
    { email = ""
    , ccNumber = ""
    , expiration = ""
    , cvv = ""
    }


type alias Model =
    { currentPage : PageType
    , stripePlan : StripePlan
    , token : Maybe String
    , creditCard : CreditCardModel
    , subscriptionResult : Maybe String
    }


type alias CreditCardModel =
    { email : String
    , ccNumber : String
    , expiration : String
    , cvv : String
    }


type StripePlan
    = Mensual
    | Semestrial
    | Annual


type PageType
    = StripeForm
    | StripeAnswer



-- VIEW


view : Model -> Node Interactive NotPhrasing Spanning NotListElement Msg
view model =
    div [ style [ fontFamilySansSerif, textCenter ] ]
        [ h1 [ style [ marginVertical large ] ] [ text "Sponsoring Paris.rb" ]
        , case model.currentPage of
            StripeForm ->
                stripeForm model

            StripeAnswer ->
                stripeAnswer model.subscriptionResult
        ]


stripeAnswer : Maybe String -> Node interactiveContent phrasingContent Spanning NotListElement msg
stripeAnswer result =
    div [] [ text (Maybe.withDefault "NO RESULT" result) ]


stripeForm : Model -> Node Interactive NotPhrasing Spanning NotListElement Msg
stripeForm model =
    div []
        [ planSelectionButtons model.stripePlan
        , subscriptionForm model
        ]


gray =
    (Color.rgba 124 124 126 0.247)


formFieldContainer =
    div
        [ style
            [ borderSolid
            , borderRadius 4
            , borderWidth 1
            , overflowHidden
            , borderColor gray
            , marginBottom medium
            ]
        ]


baseInput =
    [ padding medium
    , borderNone
    , fontSize (Px 15)
    ]
        |> compose


subscriptionForm model =
    div
        [ style
            [ borderColor Color.grey
            , borderSolid
            , borderWidth 1
            , maxWidth (Px 300)
            , padding large
            , marginAuto
            , backgroundColor (Color.rgb 245 245 247)
            , displayFlex
            , flexDirectionColumn
            ]
        ]
        [ formFieldContainer
            [ inputText [ style [ baseInput, fullWidth ], onInput (CreditCard << SetName), name "email", value model.creditCard.email, placeholder "email" ]
            ]
        , formFieldContainer
            [ inputText [ style [ baseInput, fullWidth, borderBottomColor gray, borderBottomSolid, borderBottomWidth 1 ], onInput (CreditCard << SetCcNumber), name "ccNumber", value (model.creditCard.ccNumber |> Card.numberFormat), placeholder "n° carte" ]
            , inputText [ style [ baseInput, Elegant.width (Percent 50), borderRightColor gray, borderRightSolid, borderRightWidth 1 ], onInput (CreditCard << SetExpiration), name "expiration", value (model.creditCard.expiration), placeholder "expiration" ]
            , inputText [ style [ baseInput, Elegant.width (Percent 50) ], onInput (CreditCard << SetCvv), name "cvv", value (model.creditCard.cvv |> Card.cvvFormat), placeholder "cvv" ]
            ]
        , button
            [ style
                [ backgroundColor (Color.rgb 2 162 228)
                , baseInput
                , textColor Color.white
                , bold
                , cursorPointer
                , borderRadius 4
                , marginTop medium
                ]
            , onClick AskForToken
            ]
            [ text "Sponsoriser" ]
        , p [ style [ fontSize (Px 11) ] ] [ text "La résiliation se fait par simple mail à thibaut@milesrock.com" ]
        ]


planSelectionButtons :
    StripePlan
    -> Node interactiveContent NotPhrasing Spanning NotListElement Msg
planSelectionButtons stripePlan =
    div []
        [ div [ style [ displayFlex, justifyContentCenter ] ]
            [ selectionButton Mensual "Mensuel" (Mensual == stripePlan)
            , selectionButton Semestrial "Semestriel" (Semestrial == stripePlan)
            , selectionButton Annual "Annuel" (Annual == stripePlan)
            ]
        , p [] [ stripePlanDescription stripePlan ]
        ]


selectionButton :
    StripePlan
    -> String
    -> Bool
    -> Node interactiveContent phrasingContent Spanning NotListElement Msg
selectionButton stripePlan label selected =
    let
        bg =
            Color.grayscale
                (if selected then
                    0.3
                 else
                    0.7
                )

        fg =
            Color.grayscale
                (if selected then
                    0.8
                 else
                    0.2
                )
    in
        div
            [ style
                [ h3S
                , textCenter
                , padding medium
                , textColor bg
                , backgroundColor fg
                , cursorPointer
                ]
            , hoverStyle
                [ textColor fg
                , backgroundColor bg
                ]
            , onClick (Select stripePlan)
            ]
            [ text label ]


stripePlanDescription :
    StripePlan
    -> Node interactiveContent phrasingContent spanningContent NotListElement msg
stripePlanDescription stripePlan =
    case stripePlan of
        Mensual ->
            text "450 € HT / mois"

        Semestrial ->
            text "3060 € (soit 425€ HT / mois)"

        Annual ->
            text "5832 € (soit 405€ HT / mois)"



-- UPDATE


type Msg
    = CreditCard CreditCardMsg
    | AskForToken
    | ReceiveToken String
    | ReceiveSubscription (Result Http.Error LambdaResponse)
    | Select StripePlan


type CreditCardMsg
    = SetName String
    | SetCcNumber String
    | SetExpiration String
    | SetCvv String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        CreditCard creditCardMsg ->
            ( { model
                | creditCard =
                    updateCreditCard creditCardMsg model.creditCard
              }
            , Cmd.none
            )

        AskForToken ->
            ( model
            , askForToken model.creditCard
            )

        ReceiveToken token ->
            let
                newModel =
                    { model
                        | token =
                            Just token

                        -- , creditCard = initialCreditCardModel
                    }
            in
                ( newModel
                , sendSubscription newModel
                )

        ReceiveSubscription result ->
            let
                message =
                    case result of
                        Err _ ->
                            "Une erreur est survenue, votre souscription n'a pas pu être enregistrée"

                        Ok _ ->
                            "Votre souscription a bien été enregistrée"
            in
                { model | currentPage = StripeAnswer, subscriptionResult = Just message } ! []

        Select plan ->
            ( { model | stripePlan = plan }, Cmd.none )


updateCreditCard : CreditCardMsg -> CreditCardModel -> CreditCardModel
updateCreditCard msg model =
    case msg of
        SetName email ->
            { model | email = email }

        SetCcNumber ccNumber ->
            { model | ccNumber = ccNumber |> Card.onlyNumbers }

        SetExpiration expiration ->
            { model | expiration = expiration |> Card.onlyNumbersAndSlash }

        SetCvv cvv ->
            { model | cvv = cvv |> Card.onlyNumbers }



-- PORTS


port askForToken : CreditCardModel -> Cmd msg


port receiveStripeToken : (String -> msg) -> Sub msg



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ receiveStripeToken ReceiveToken ]



-- HTTP.POST


sendSubscription : Model -> Cmd Msg
sendSubscription model =
    Http.send ReceiveSubscription (postSubscription model)


postSubscription : Model -> Http.Request LambdaResponse
postSubscription model =
    let
        endPoint =
            "https://n3t7k7q6h0.execute-api.eu-west-2.amazonaws.com/dev/stripePayment"

        stripePlanId =
            case model.stripePlan of
                Mensual ->
                    "mensual-parisrb"

                Semestrial ->
                    "semestrial ParisRB"

                Annual ->
                    "annual-parisrb"

        body =
            [ ( "stripePlanId", Encode.string stripePlanId )
            , ( "stripeEmail", Encode.string model.creditCard.email )
            , ( "stripeToken", Encode.string (Maybe.withDefault "" model.token) )
            ]
                |> Encode.object
                |> Http.jsonBody
    in
        Http.post endPoint body decodeLambdaResponse


type alias LambdaResponse =
    { message : String }


decodeLambdaResponse : Decode.Decoder LambdaResponse
decodeLambdaResponse =
    Decode.map LambdaResponse
        (Decode.field "message" Decode.string)
