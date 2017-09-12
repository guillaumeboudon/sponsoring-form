module Sponsoring exposing (..)

import BodyBuilder exposing (..)
import BodyBuilder.Elements
import Elegant exposing (textCenter, padding, SizeUnit(..), fontSize)
import Elegant.Elements exposing (..)
import Color


type alias Model =
    { currentStripePlan : StripePlan
    }


type Msg
    = Select StripePlan


type StripePlan
    = Mensual
    | Semestrial
    | Annual


plansIndex : StripePlan -> Node Msg
plansIndex stripePlan =
    div
        [ style
            [ Elegant.backgroundColor Color.white
            , Elegant.height (Vh 100)
            , Elegant.overflowYScroll
            , Elegant.fullWidth
            ]
        ]
        [ div
            [ style
                [ Elegant.h1S
                , Elegant.textCenter
                , Elegant.padding Elegant.medium
                ]
            ]
            [ text "Sponsoring ParisRB" ]
        , div [ style [ centerHorizontal ] ]
            [ div [ style [ Elegant.displayFlex ] ]
                [ selectionButton Mensual "Mensuel" (Mensual == stripePlan)
                , selectionButton Semestrial "Semestriel" (Semestrial == stripePlan)
                , selectionButton Annual "Annuel" (Annual == stripePlan)
                ]
            ]
        , div []
            [ div [ id (toString stripePlan), style [ textCenter ] ]
                [ stripeButton Mensual stripePlan
                , stripeButton Semestrial stripePlan
                , stripeButton Annual stripePlan
                ]
            ]
        ]


getStripeData : StripePlan -> List ( String, String )
getStripeData stripePlan =
    let
        commonData =
            [ ( "image", "https://stripe.com/img/documentation/checkout/marketplace.png" )
            , ( "key", "##stripe_key##" )
            , ( "panel-label", "Sponsoriser" )
            , ( "currency", "EUR" )
            , ( "allow-remember-me", "false" )
            ]

        planData =
            case stripePlan of
                Mensual ->
                    [ ( "name", "Sponsoring mensuel" )
                    , ( "description", "450€ HT / mois" )
                    , ( "label", "Sponsoriser au mois" )
                    , ( "amount", "54000" )
                    ]

                Semestrial ->
                    [ ( "name", "Sponsoring 6 mois" )
                    , ( "description", "425€ HT / mois" )
                    , ( "label", "Sponsoriser aux 6 mois" )
                    , ( "amount", "306000" )
                    ]

                Annual ->
                    [ ( "name", "Sponsoring annuel" )
                    , ( "description", "405€ HT / mois" )
                    , ( "label", "Sponsoriser à l'année" )
                    , ( "amount", "583200" )
                    ]
    in
        commonData ++ planData


selectionButton : StripePlan -> String -> Bool -> Node Msg
selectionButton msg label selected =
    div
        [ style
            [ Elegant.h3S
            , Elegant.textCenter
            , Elegant.padding Elegant.medium
            ]
        , BodyBuilder.Elements.invertableButton
            (Color.grayscale
                (if selected then
                    0.7
                 else
                    0.3
                )
            )
            (Color.grayscale
                (if selected then
                    0.2
                 else
                    0.8
                )
            )
        , onClick (Select msg)
        ]
        [ text label ]


stripeButton : StripePlan -> StripePlan -> Node msg
stripeButton stripePlan currentStripePlan =
    div
        [ style
            (if stripePlan == currentStripePlan then
                []
             else
                [ Elegant.displayNone ]
            )
        ]
        [ formPost "https://123123123123.execute-api.us-west-2.amazonaws.com/production"
            []
            [ script
                [ src ("https://checkout.stripe.com/checkout.js")
                , class [ "stripe-button" ]
                , data (getStripeData stripePlan)
                ]
            ]
        ]


view : Model -> Node Msg
view model =
    div [ style [ Elegant.fontFamilySansSerif, Elegant.fontSize Elegant.zeta ] ]
        [ plansIndex model.currentStripePlan ]


update : Msg -> Model -> ( Model, Cmd msg )
update msg model =
    case msg of
        Select val ->
            ( { model | currentStripePlan = val }, Cmd.none )


init : ( Model, Cmd Msg )
init =
    ( Model Mensual, Cmd.none )


main : Program Never Model Msg
main =
    program
        { init = init
        , update = update
        , subscriptions = always Sub.none
        , view = view
        }
